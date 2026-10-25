import 'package:digitalpharmacy/core/config/api_country_bindings.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

class _PendingCountry {
  final response = Completer<ResponseBody>();
  bool cancelled = false;

  void succeed() => response.complete(
    _json([
      {'id': 7, 'name': 'Jordan'},
    ]),
  );
}

ResponseBody _json(Object data) => ResponseBody.fromString(
  jsonEncode(data),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Real Dio cancellation/decoding, with no sockets or live server fixtures.
class _CountryAdapter implements HttpClientAdapter {
  final firstCountry = Completer<_PendingCountry>();
  final countries = <_PendingCountry>[];
  final medicationQueries = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/GetCountries') {
      final pending = _PendingCountry();
      countries.add(pending);
      if (!firstCountry.isCompleted) firstCountry.complete(pending);
      cancelFuture?.then(
        (_) => pending.cancelled = true,
        onError: (Object _) => pending.cancelled = true,
      );
      return pending.response.future;
    }
    expect(options.path, '/api/GetMedicationSelect');
    medicationQueries.add(options.queryParameters['StringSerch'] as String?);
    return _json({
      'status': 200,
      'data': {
        'data': [
          {
            'id': 17,
            'tradeName': 'Fresh result',
            'scientificName': 'Synthetic',
          },
        ],
        'meta': {
          'pageNumber': 1,
          'totalPages': 1,
          'totalCount': 1,
          'hasPreviousPage': false,
          'hasNextPage': false,
        },
      },
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() => setAppCountry(AppCountry.jordan));

  test(
    'cancelling one country waiter must not cancel the current query',
    () async {
      final adapter = _CountryAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://144.91.111.63:5002'))
        ..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final session = AuthSession();
      addTearDown(session.dispose);
      final api = ApiService(
        countryBindings: const ApiCountryBindings(),
        client: ApiTransport(dio: dio, authSession: session),
      );
      final oldToken = CancelToken();
      final currentToken = CancelToken();
      final old = api.fetchMedicationSuggestionPage(
        query: 'old',
        searchType: MedicationSearchType.tradeName,
        pageNumber: 1,
        pageSize: 20,
        cancelToken: oldToken,
      );
      final country = await adapter.firstCountry.future;
      final oldOutcome = expectLater(
        old,
        throwsA(
          isA<DioException>().having(CancelToken.isCancel, 'cancelled', true),
        ),
      );
      oldToken.cancel('Superseded query');
      // Same synchronous transition as replacing an in-flight submitted search.
      final current = api.fetchMedicationSuggestionPage(
        query: 'sentry',
        searchType: MedicationSearchType.tradeName,
        pageNumber: 1,
        pageSize: 20,
        cancelToken: currentToken,
      );
      final currentOutcome = expectLater(
        current,
        completion(
          isA<ApiPage>().having((page) => page.items.length, 'rows', 1),
        ),
      );
      country.succeed();
      await Future.wait([oldOutcome, currentOutcome]);
      expect(currentToken.isCancelled, isFalse);
      expect(country.cancelled, isFalse);
      expect(adapter.countries, hasLength(1));
      expect(adapter.medicationQueries, ['sentry']);
    },
  );

  test(
    'scope reset cancels old lookup without evicting the new cache',
    () async {
      final adapter = _CountryAdapter();
      final api = _service(adapter);
      final old = _search(api, 'old');
      final first = await adapter.firstCountry.future;
      final oldOutcome = expectLater(old, throwsA(isA<DioException>()));
      api.clearSessionCache();
      final current = _search(api, 'sentry');
      final second = await _countryAt(adapter, 1);
      first.succeed();
      second.succeed();
      await Future.wait([oldOutcome, current]);
      await _search(api, 'cached').timeout(const Duration(seconds: 1));
      expect(first.cancelled, isTrue);
      expect(adapter.countries, hasLength(2));
      expect(adapter.medicationQueries, ['sentry', 'cached']);
    },
  );

  test(
    'stalled country lookup times out, aborts and permits a fresh retry',
    () async {
      final adapter = _CountryAdapter();
      final api = _service(adapter, deadline: const Duration(milliseconds: 30));
      final pending = _search(api, 'sentry');
      final first = await adapter.firstCountry.future;
      await expectLater(
        pending,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'timeout',
            DioExceptionType.receiveTimeout,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(first.cancelled, isTrue);
      final retry = _search(api, 'sentry');
      (await _countryAt(adapter, 1)).succeed();
      expect((await retry).items, hasLength(1));
      expect(adapter.countries, hasLength(2));
      expect(adapter.medicationQueries, ['sentry']);
    },
  );
}

ApiService _service(
  _CountryAdapter adapter, {
  Duration deadline = const Duration(seconds: 30),
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://144.91.111.63:5002'))
    ..httpClientAdapter = adapter;
  addTearDown(dio.close);
  final session = AuthSession();
  addTearDown(session.dispose);
  final api = ApiService(
    countryBindings: const ApiCountryBindings(),
    client: ApiTransport(dio: dio, authSession: session),
    countryLookupTimeout: deadline,
  );
  addTearDown(api.clearSessionCache);
  return api;
}

Future<ApiPage> _search(ApiService api, String query) =>
    api.fetchMedicationSuggestionPage(
      query: query,
      searchType: MedicationSearchType.tradeName,
      pageNumber: 1,
      pageSize: 20,
    );

Future<_PendingCountry> _countryAt(_CountryAdapter adapter, int index) async {
  final until = DateTime.now().add(const Duration(seconds: 1));
  while (adapter.countries.length <= index) {
    if (DateTime.now().isAfter(until)) {
      fail('Expected country request did not start');
    }
    await Future<void>.delayed(Duration.zero);
  }
  return adapter.countries[index];
}
