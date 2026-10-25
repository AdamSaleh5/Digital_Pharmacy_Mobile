import 'dart:async';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/api_auth_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

const _authorizationHeader = 'Authorization';

void main() {
  const secureBaseUrl = 'https://api.example.test';

  Dio fakeDio(
    List<RequestOptions> requests,
    Response<dynamic> Function(RequestOptions request) respond,
  ) {
    final dio = Dio(BaseOptions(baseUrl: secureBaseUrl));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(respond(options));
        },
      ),
    );
    return dio;
  }

  test(
    'valid login posts the documented fields and keeps token in memory',
    () async {
      final requests = <RequestOptions>[];
      final session = AuthSession();
      final service = ApiAuthService(
        baseUrl: secureBaseUrl,
        verifiedOrigin: secureBaseUrl,
        session: session,
        dio: fakeDio(
          requests,
          (request) => Response<dynamic>(
            requestOptions: request,
            statusCode: 200,
            data: {'accessToken': 'synthetic-token'},
          ),
        ),
      );

      await service.login(
        email: ' example@example.test ',
        password: 'synthetic',
      );

      expect(session.isSignedIn, isTrue);
      expect(requests, hasLength(1));
      expect(requests.single.uri.path, '/api/auth/login');
      expect(requests.single.data, {
        'email': 'example@example.test',
        'password': 'synthetic',
      });
      expect(_hasAuthorization(requests.single), isFalse);
      expect(requests.single.followRedirects, isFalse);
    },
  );

  test('missing accessToken fails closed', () async {
    final requests = <RequestOptions>[];
    final session = AuthSession();
    final service = ApiAuthService(
      baseUrl: secureBaseUrl,
      verifiedOrigin: secureBaseUrl,
      session: session,
      dio: fakeDio(
        requests,
        (request) => Response<dynamic>(
          requestOptions: request,
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      ),
    );

    await expectLater(
      service.login(email: 'example@example.test', password: 'synthetic'),
      throwsA(
        isA<ApiAuthException>().having(
          (error) => error.failure,
          'failure',
          ApiAuthFailure.invalidToken,
        ),
      ),
    );
    expect(session.isSignedIn, isFalse);
  });

  test('null accessToken fails closed', () async {
    final requests = <RequestOptions>[];
    final session = AuthSession();
    final service = ApiAuthService(
      baseUrl: secureBaseUrl,
      verifiedOrigin: secureBaseUrl,
      session: session,
      dio: fakeDio(
        requests,
        (request) => Response<dynamic>(
          requestOptions: request,
          statusCode: 200,
          data: {'accessToken': null},
        ),
      ),
    );

    await expectLater(
      service.login(email: 'example@example.test', password: 'synthetic'),
      throwsA(isA<ApiAuthException>()),
    );
    expect(session.isSignedIn, isFalse);
  });

  test(
    'login 401 clears the session and explicit logout clears it too',
    () async {
      final requests = <RequestOptions>[];
      final session =
          AuthSession()..start(
            accessToken: 'synthetic-old-token',
            apiOrigin: Uri.parse(secureBaseUrl),
          );
      final service = ApiAuthService(
        baseUrl: secureBaseUrl,
        verifiedOrigin: secureBaseUrl,
        session: session,
        dio: fakeDio(
          requests,
          (request) => Response<dynamic>(
            requestOptions: request,
            statusCode: 401,
            data: {'detail': 'synthetic unauthorized'},
          ),
        ),
      );

      await expectLater(
        service.login(email: 'example@example.test', password: 'synthetic'),
        throwsA(
          isA<ApiAuthException>().having(
            (error) => error.failure,
            'failure',
            ApiAuthFailure.unauthorized,
          ),
        ),
      );
      expect(session.isSignedIn, isFalse);
      expect(_hasAuthorization(requests.single), isFalse);

      session.start(
        accessToken: 'synthetic-token',
        apiOrigin: Uri.parse(secureBaseUrl),
      );
      service.logout();
      expect(session.isSignedIn, isFalse);
    },
  );

  test('fixed HTTP origin blocks credentials before dispatch', () async {
    final requests = <RequestOptions>[];
    final session = AuthSession();
    final service = ApiAuthService(
      baseUrl: 'http://144.91.111.63:5002',
      session: session,
      dio: fakeDio(
        requests,
        (request) => Response<dynamic>(
          requestOptions: request,
          statusCode: 200,
          data: {'accessToken': 'synthetic-token'},
        ),
      ),
    );
    expect(service.isSignInConfigured, isFalse);
    await expectLater(
      service.login(
        email: 'synthetic@example.test',
        password: 'synthetic-password',
      ),
      throwsA(
        isA<ApiAuthException>().having(
          (e) => e.failure,
          'failure',
          ApiAuthFailure.httpsRequired,
        ),
      ),
    );
    expect(requests, isEmpty);
    expect(session.isSignedIn, isFalse);
  });

  test(
    'anonymous API reads remain available on the configured HTTP origin',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://144.91.111.63:5002'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'synthetic': true},
              ),
            );
          },
        ),
      );
      final transport = ApiTransport(
        dio: dio,
        authSession: AuthSession(),
        baseUrl: 'http://144.91.111.63:5002',
      );

      final response = await transport.get<dynamic>('/api/GetMedicationSelect');

      expect(response.statusCode, 200);
      expect(requests.single.uri.origin, 'http://144.91.111.63:5002');
      expect(_hasAuthorization(requests.single), isFalse);
    },
  );

  test('HTTPS host without explicit verification is also blocked', () async {
    final requests = <RequestOptions>[];
    final service = ApiAuthService(
      baseUrl: secureBaseUrl,
      session: AuthSession(),
      dio: fakeDio(
        requests,
        (request) => Response<dynamic>(
          requestOptions: request,
          statusCode: 200,
          data: {'accessToken': 'synthetic-token'},
        ),
      ),
    );

    expect(service.isHttpsConfigured, isFalse);
    await expectLater(
      service.login(email: 'synthetic@example.test', password: 'synthetic'),
      throwsA(
        isA<ApiAuthException>().having(
          (error) => error.failure,
          'failure',
          ApiAuthFailure.httpsRequired,
        ),
      ),
    );
    expect(requests, isEmpty);
  });

  test(
    'transport scopes bearer header to the configured HTTPS origin',
    () async {
      final requests = <RequestOptions>[];
      final session =
          AuthSession()..start(
            accessToken: 'synthetic-token',
            apiOrigin: Uri.parse(secureBaseUrl),
          );
      final dio = Dio(BaseOptions(baseUrl: secureBaseUrl));
      final transport = ApiTransport(
        dio: dio,
        authSession: session,
        baseUrl: secureBaseUrl,
        verifiedOrigin: secureBaseUrl,
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(requestOptions: options, statusCode: 200),
            );
          },
        ),
      );

      await transport.get<dynamic>('/api/GetCountries');
      await dio.getUri<dynamic>(
        Uri.parse('https://other.example.test/private'),
        options: Options(
          headers: const {'Authorization': 'Bearer caller-token'},
        ),
      );

      expect(
        requests[0].headers[_authorizationHeader],
        'Bearer synthetic-token',
      );
      expect(requests[0].followRedirects, isFalse);
      expect(_hasAuthorization(requests[1]), isFalse);
    },
  );

  test('API 401 clears the in-memory session', () async {
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-token',
          apiOrigin: Uri.parse(secureBaseUrl),
        );
    final dio = Dio(BaseOptions(baseUrl: secureBaseUrl));
    final transport = ApiTransport(
      dio: dio,
      authSession: session,
      baseUrl: secureBaseUrl,
      verifiedOrigin: secureBaseUrl,
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 401,
              data: {'detail': 'synthetic unauthorized'},
            ),
          );
        },
      ),
    );

    await transport.get<dynamic>('/api/protected');
    expect(session.isSignedIn, isFalse);
  });

  test(
    'late authenticated response is discarded after account switch',
    () async {
      final session =
          AuthSession()..start(
            accessToken: 'synthetic-account-one',
            apiOrigin: Uri.parse(secureBaseUrl),
          );
      final dio = Dio(BaseOptions(baseUrl: secureBaseUrl));
      final transport = ApiTransport(
        dio: dio,
        authSession: session,
        baseUrl: secureBaseUrl,
        verifiedOrigin: secureBaseUrl,
      );
      final requestSeen = Completer<RequestOptions>();
      final responseReady = Completer<Response<dynamic>>();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestSeen.complete(options);
            responseReady.future.then(handler.resolve);
          },
        ),
      );

      final pending = transport.get<dynamic>('/api/private');
      final request = await requestSeen.future;
      expect(
        request.headers[_authorizationHeader],
        'Bearer synthetic-account-one',
      );
      session.start(
        accessToken: 'synthetic-account-two',
        apiOrigin: Uri.parse(secureBaseUrl),
      );
      responseReady.complete(
        Response<dynamic>(
          requestOptions: request,
          statusCode: 200,
          data: {'synthetic': 'old account data'},
        ),
      );

      await expectLater(
        pending,
        throwsA(
          isA<DioException>().having(
            (error) => error.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
    },
  );
}

bool _hasAuthorization(RequestOptions request) => request.headers.keys.any(
  (key) => key.toLowerCase() == _authorizationHeader.toLowerCase(),
);
