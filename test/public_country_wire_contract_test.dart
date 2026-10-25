import 'package:digitalpharmacy/core/config/api_country_bindings.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/api_errors.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

// No sockets or real tokens. Capture after actual Dio request interceptors,
// unlike a short-circuiting onRequest fixture that might skip those interceptors.
class _CountryContractWire implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.uri.path == '/api/GetCountries') {
      return ResponseBody.fromString(
        jsonEncode({
          'status': 401,
          'message':
              'A valid access token is required to access this resource.',
          'data': null,
        }),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.uri.path == '/api/GetCompanySeletc') {
      return ResponseBody.fromString(
        jsonEncode({
          'status': 200,
          'message': 'Synthetic public fixture',
          'data': {
            'data': [
              {
                'id': 17,
                'company': 'Synthetic public company',
                'agent': 'Synthetic agent',
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
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    fail('No undocumented fallback may be dispatched: ${options.uri.path}');
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const origin = 'http://144.91.111.63:5002';
  late _CountryContractWire wire;
  late Dio dio;
  late ApiService api;
  setUp(() {
    wire = _CountryContractWire();
    final transport = ApiTransport();
    dio = transport.dio..httpClientAdapter = wire;
    api = ApiService(
      countryBindings: const ApiCountryBindings(),
      client: transport,
    );
  });
  tearDown(() {
    dio.close();
    AuthSession.shared.signOut();
  });

  test(
    'actual anonymous country request matches published sole read operation and real public 401 shape',
    () async {
      final spec =
          jsonDecode(
                File(
                  'docs/integration-audit-20261014/public-contract-followup-20261015/swagger.json',
                ).readAsStringSync(),
              )
              as Map;
      final operation = spec['paths']['/api/GetCountries']['get'] as Map;
      expect(operation['parameters'] ?? [], isEmpty);
      expect(operation.containsKey('security'), isFalse);
      expect(spec['security'], [
        {'Bearer': []},
      ]);
      expect(operation['responses']['200'].containsKey('content'), isFalse);
      final countryReads =
          (spec['paths'] as Map).entries
              .where(
                (entry) =>
                    entry.key.toString().toLowerCase().contains('countr') &&
                    (entry.value as Map).containsKey('get'),
              )
              .map((entry) => entry.key)
              .toList();
      expect(countryReads, ['/api/GetCountries']);
      // Even a separate legacy admin session must never enter the app request.
      AuthSession.shared.start(
        accessToken: 'synthetic-admin-not-transmitted',
        apiOrigin: Uri.parse('https://api.example.test'),
      );
      await expectLater(
        api.fetchCountries(),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'actual public response shape',
            401,
          ),
        ),
      );
      final request = wire.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.toString(), '$origin/api/GetCountries');
      expect(request.queryParameters, isEmpty);
      expect(request.data, isNull);
      expect(
        request.headers.keys.map((key) => key.toLowerCase()),
        isNot(contains('authorization')),
      );
      expect(
        request.headers.keys.map((key) => key.toLowerCase()),
        isNot(contains('cookie')),
      );
      expect(request.headers['Accept'], 'application/json');
      expect(request.followRedirects, isFalse);
      expect(AuthSession.shared.isSignedIn, isTrue);
    },
  );

  test(
    'country access failure remains an error without fallback ID or route; independent public catalogue stays available',
    () async {
      Object? observed;
      try {
        await api.fetchMedicationSuggestionPage(
          searchType: MedicationSearchType.tradeName,
          pageNumber: 1,
          pageSize: 20,
        );
      } catch (error) {
        observed = error;
      }
      expect(observed, isA<DioException>());
      expect(wire.requests.map((request) => request.uri.path), [
        '/api/GetCountries',
      ]);
      final message = apiFailureMessage(observed!, AppLocalizationsEn());
      expect(message.toLowerCase(), isNot(contains('sign in')));
      expect(isApiFailureRetryable(observed), isTrue);
      final page = await api.fetchCompanyPage(pageNumber: 1, pageSize: 20);
      expect(page.items.single.id, 17);
      final catalogue = wire.requests.last;
      expect(catalogue.uri.path, '/api/GetCompanySeletc');
      expect(catalogue.queryParameters, {'PageNumber': 1, 'PageSize': 20});
      expect(
        catalogue.headers.keys.map((key) => key.toLowerCase()),
        isNot(contains('authorization')),
      );
      expect(wire.requests, hasLength(2));
    },
  );
}
