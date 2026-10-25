import 'package:digitalpharmacy/core/config/api_country_bindings.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/config/app_config.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Immutable snapshot of the exact public HTTP Swagger fetched in this audit.
  final spec =
      jsonDecode(
            File(
              'docs/integration-audit-20261014/ad-api-audit-20261015/swagger.json',
            ).readAsStringSync(),
          )
          as Map;
  final paths = spec['paths'] as Map;
  Map schema(Map value) =>
      value.containsKey(r'$ref')
          ? spec['components']['schemas'][(value[r'$ref'] as String)
                  .split('/')
                  .last]
              as Map
          : value;
  void validate(Object? value, Map definition) {
    final s = schema(definition);
    switch (s['type']) {
      case 'integer':
        expect(value, isA<int>());
      case 'boolean':
        expect(value, isA<bool>());
      case 'string':
        expect(value, isA<String>());
    }
    if (s['enum'] is List) expect(s['enum'], contains(value));
  }

  test(
    'actual runtime requests match current published methods, parameter names, types and enums',
    () async {
      final previousCountry = kAppCountry;
      setAppCountry(AppCountry.jordan);
      addTearDown(() => setAppCountry(previousCountry));
      const origin = 'https://api.example.test';
      final session = AuthSession();
      addTearDown(session.dispose);
      session.start(
        accessToken: 'synthetic-unit-session',
        apiOrigin: Uri.parse(origin),
      );
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: origin));
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            final path = request.uri.path;
            expect(request.uri.origin, origin);
            expect(request.headers['Authorization'], isNull);
            expect(request.followRedirects, isFalse);
            final operation =
                paths[path]?[request.method.toLowerCase()] as Map?;
            expect(
              operation,
              isNotNull,
              reason: 'Every emitted method/path must exist in latest Swagger',
            );
            final parameters = {
              for (final p in (operation!['parameters'] as List? ?? []))
                p['name']: p['schema'] as Map,
            };
            expect(
              request.queryParameters.keys,
              everyElement(isIn(parameters.keys)),
            );
            for (final entry in request.queryParameters.entries) {
              validate(entry.value, parameters[entry.key]!);
            }
            if (request.data is Map) {
              final bodySchema = schema(
                operation['requestBody']['content']['application/json']['schema']
                    as Map,
              );
              final properties = bodySchema['properties'] as Map;
              expect(
                (request.data as Map).keys,
                everyElement(isIn(properties.keys)),
              );
              for (final key in bodySchema['required'] as List? ?? []) {
                expect(request.data, contains(key));
              }
              for (final entry in (request.data as Map).entries) {
                validate(entry.value, properties[entry.key] as Map);
              }
            }
            Object body;
            if (path == '/api/GetCountries') {
              body = [
                {'id': 73, 'name': 'Jordan'},
              ]; // Synthetic lookup ID, never sent to live API.
            } else if (path == '/api/auth/login') {
              body = {'accessToken': 'synthetic-unit-login'};
            } else if (path == '/api/users/verify-device') {
              body = {'syntheticUnconfirmedFixture': true};
            } else {
              final Map<String, Object> item = switch (path) {
                '/api/GetMedicationSelect' => {
                  'id': 17,
                  'tradeName': 'Synthetic product',
                  'scientificName': 'Synthetic ingredient',
                },
                '/api/GetCompanySeletc' => {
                  'id': 17,
                  'company': 'Synthetic company',
                  'agent': 'Synthetic agent',
                },
                '/api/GetAgentSeletc' => {'id': 17, 'value': 'Synthetic agent'},
                '/api/GetPharmacies' => {
                  'id': 17,
                  'name': 'Synthetic pharmacy',
                  'address': 'Synthetic',
                  'managerName': 'Synthetic',
                  'phoneNumber': 'synthetic-not-a-phone',
                },
                _ => {
                  'id': 17,
                  'tradeName': 'Synthetic product',
                  'scientificName': 'Synthetic ingredient',
                  'company': 'Synthetic company',
                  'agent': 'Synthetic agent',
                  'price': 2.5,
                  'pharmaceuticalForm': 'Synthetic tablet',
                },
              };
              body = {
                'status': 200,
                'data': {
                  'data': [item],
                  'meta': {
                    'pageNumber': 1,
                    'totalPages': 1,
                    'totalCount': 1,
                    'hasPreviousPage': false,
                    'hasNextPage': false,
                  },
                },
              };
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: request,
                statusCode: 200,
                data: body,
              ),
            );
          },
        ),
      );
      final api = ApiService(
        countryBindings: const ApiCountryBindings(),
        client: ApiTransport(dio: dio, baseUrl: origin),
      );
      await api.fetchCountries();
      for (final type in MedicationSearchType.values) {
        await api.fetchMedicationSuggestionPage(
          searchType: type,
          query: 'synthetic',
          pageNumber: 1,
          pageSize: 20,
        );
        await api.fetchMedicationDetailsPage(
          id: 17,
          searchType: type,
          pageNumber: 1,
          pageSize: 20,
        );
      }
      await api.fetchCompanyPage(pageNumber: 1, pageSize: 20);
      await api.fetchMedicationPageByCompany(
        companyId: 17,
        pageNumber: 1,
        pageSize: 20,
      );
      await api.fetchAgents();
      await api.fetchPharmaceuticalForms(id: 17);
      await api.fetchMedicationPageByAgent(
        agentId: 17,
        pageNumber: 1,
        pageSize: 20,
      );
      for (final type in PharmacySearchType.values) {
        await api.fetchPharmacyPage(
          query: 'synthetic',
          searchType: type,
          pageNumber: 1,
          pageSize: 20,
        );
      }
      final result = await ActivationService(
        dio: dio,
        session: session,
        apiOrigin: Uri.parse(origin),
      ).verifyDevice(
        activationCode: 'synthetic-only',
        isNewUser: false,
        deviceId: 'synthetic-installation-not-a-token',
      );
      expect(result, ActivationVerification.unconfirmed);
      expect(requests.map((r) => r.uri.path).toSet(), {
        '/api/GetCountries',
        '/api/GetMedicationSelect',
        '/api/GetMedicationDetails',
        '/api/GetCompanySeletc',
        '/api/GetMedicationDetailsByCompany',
        '/api/GetAgentSeletc',
        '/api/GetMedicationDetailsByAgent',
        '/api/GetPharmacies',
        '/api/GetPharmaceuticalForm',
        '/api/users/verify-device',
      });
      final count = requests.length;
      await expectLater(
        api.fetchAlternatives(17),
        throwsA(isA<ApiContractUnavailable>()),
      );
      expect(
        requests,
        hasLength(count),
        reason:
            'Unspecified alternative linkage cannot invent outgoing requests',
      );
    },
  );
}
