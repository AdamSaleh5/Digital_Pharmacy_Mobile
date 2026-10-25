import 'dart:async';
import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/features/drugs/data/models/company_agent_item.dart';
import 'package:digitalpharmacy/features/drugs/data/models/agent_catalog_item.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api extends ApiService {
  final countries = <AppCountry>[];
  Completer<void>? hold;
  Future<String> label() async {
    final country = kAppCountry;
    countries.add(country);
    final pending = hold;
    hold = null;
    if (pending != null) await pending.future;
    return '${country.name}-${countries.length}';
  }

  @override
  Future<List<CompanyAgentItem>> fetchCompanies({
    String? query,
    CancelToken? cancelToken,
  }) async => [
    CompanyAgentItem.fromJson({
      'id': 17,
      'company': await label(),
      'agent': 'Synthetic',
    }),
  ];
  @override
  Future<List<AgentCatalogItem>> fetchAgents({
    String? query,
    CancelToken? cancelToken,
  }) async => [
    AgentCatalogItem.fromJson({'id': 17, 'value': await label()}),
  ];
}

void main() {
  final initial = kAppCountry;
  setUp(() => setAppCountry(AppCountry.jordan));
  tearDown(() => setAppCountry(initial));
  for (final companies in [true, false]) {
    Future<String> load(MedicationRepository repo) async =>
        companies
            ? (await repo.fetchCompanies(fetchInitial: true)).single.company
            : (await repo.fetchAgents(fetchInitial: true)).single.value;
    test(
      'catalogue cache isolates Jordan and Palestine without relying on provider invalidation, companies=$companies',
      () async {
        final api = _Api();
        final repo = MedicationRepository(api: api);
        expect(await load(repo), startsWith('jordan'));
        setAppCountry(AppCountry.palestine);
        expect(await load(repo), startsWith('palestine'));
        expect(api.countries, [AppCountry.jordan, AppCountry.palestine]);
      },
    );
    test(
      'obsolete catalogue cannot repopulate caches after country change or explicit invalidation, companies=$companies',
      () async {
        final api = _Api();
        final repo = MedicationRepository(api: api);
        api.hold = Completer<void>();
        final release = api.hold!;
        final stale = load(repo);
        final checked = expectLater(
          stale,
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'stale result',
              DioExceptionType.cancel,
            ),
          ),
        );
        setAppCountry(AppCountry.palestine);
        repo.clearSessionCaches();
        expect(await load(repo), startsWith('palestine'));
        release.complete();
        await checked;
        expect(await load(repo), startsWith('palestine'));
        expect(api.countries, hasLength(2));
      },
    );
  }
  test(
    'explicit repository country cannot label a different global-country response',
    () async {
      final api = _Api();
      final repo = MedicationRepository(api: api);
      await expectLater(
        repo.companyMedicationsPaged(
          companyId: 17,
          page: 1,
          country: AppCountry.palestine,
        ),
        throwsArgumentError,
      );
      expect(api.countries, isEmpty);
    },
  );
}
