import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/api_auth_service.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

const _origin = 'https://api.example.test';

/// Completer-backed adapter only: no socket, real code, token or server request.
class _UnauthorizedAdapter implements HttpClientAdapter {
  final requestSeen = Completer<RequestOptions>();
  final responseReady = Completer<ResponseBody>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requestSeen.complete(options);
    return responseReady.future;
  }

  void respond() {
    responseReady.complete(
      ResponseBody.fromString(
        '{"detail":"synthetic unauthorized"}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

void _startSession(AuthSession session) {
  // Reusing the value deliberately proves revision, not token equality, wins.
  session.start(
    accessToken: 'synthetic-not-transmitted',
    apiOrigin: Uri.parse(_origin),
  );
}

Matcher get _unauthorized => isA<DioException>().having(
  (error) => error.response?.statusCode,
  'HTTP status',
  401,
);

void main() {
  for (final accepts401 in [true, false]) {
    for (final directDio in [false, true]) {
      for (final scenario in ['current', 'replaced', 'anonymous']) {
        test(
          '401 session=$scenario accepted=$accepts401 directDio=$directDio',
          () async {
            final session = AuthSession();
            addTearDown(session.dispose);
            if (scenario != 'anonymous') _startSession(session);
            final adapter = _UnauthorizedAdapter();
            final dio = Dio(
              BaseOptions(
                baseUrl: _origin,
                validateStatus: accepts401 ? (_) => true : null,
              ),
            )..httpClientAdapter = adapter;
            addTearDown(dio.close);
            final transport = ApiTransport(
              dio: dio,
              authSession: session,
              baseUrl: _origin,
              verifiedOrigin: _origin,
            );
            final pending =
                directDio
                    ? dio.get<dynamic>('/api/GetCountries')
                    : transport.get<dynamic>('/api/GetCountries');
            final request = await adapter.requestSeen.future;
            expect(
              request.headers.containsKey('Authorization'),
              scenario != 'anonymous',
            );
            if (scenario != 'current') _startSession(session);
            final revisionBeforeResponse = session.revision;
            final outcome =
                accepts401
                    ? expectLater(
                      pending,
                      completion(
                        isA<Response<dynamic>>().having(
                          (response) => response.statusCode,
                          'HTTP status',
                          401,
                        ),
                      ),
                    )
                    : expectLater(pending, throwsA(_unauthorized));
            adapter.respond();
            await outcome;
            expect(session.isSignedIn, scenario != 'current');
            expect(
              session.revision,
              revisionBeforeResponse + (scenario == 'current' ? 1 : 0),
            );
          },
        );
      }
    }
  }

  for (final replaceSession in [false, true]) {
    test(
      'anonymous activation 401 never mutates admin session, replacement=$replaceSession',
      () async {
        final session = AuthSession();
        addTearDown(session.dispose);
        _startSession(session);
        final adapter = _UnauthorizedAdapter();
        final dio = Dio()..httpClientAdapter = adapter;
        addTearDown(dio.close);
        final verifier = ActivationService(
          dio: dio,
          session: session,
          apiOrigin: Uri.parse(_origin),
        );
        final pending = verifier.verifyDevice(
          activationCode: 'synthetic-not-transmitted',
        );
        final request = await adapter.requestSeen.future;
        expect(request.headers['Authorization'], isNull);
        if (replaceSession) _startSession(session);
        final revisionBeforeResponse = session.revision;
        final outcome = expectLater(pending, throwsA(_unauthorized));
        adapter.respond();
        await outcome;
        expect(session.isSignedIn, isTrue);
        expect(session.revision, revisionBeforeResponse);
      },
    );
  }

  for (final asDioError in [false, true]) {
    for (final replaceSession in [false, true]) {
      test(
        'login 401 preserves newer session=$replaceSession DioError=$asDioError',
        () async {
          final session = AuthSession();
          addTearDown(session.dispose);
          _startSession(session);
          final adapter = _UnauthorizedAdapter();
          final dio = Dio()..httpClientAdapter = adapter;
          addTearDown(dio.close);
          if (asDioError) {
            dio.interceptors.add(
              InterceptorsWrapper(
                onResponse: (response, handler) {
                  handler.reject(
                    DioException(
                      requestOptions: response.requestOptions,
                      response: response,
                      type: DioExceptionType.badResponse,
                    ),
                  );
                },
              ),
            );
          }
          final service = ApiAuthService(
            dio: dio,
            session: session,
            baseUrl: _origin,
            verifiedOrigin: _origin,
          );
          final pending = service.login(
            email: 'synthetic@example.test',
            password: 'synthetic-not-transmitted',
          );
          await adapter.requestSeen.future;
          if (replaceSession) _startSession(session);
          final revisionBeforeResponse = session.revision;
          final outcome = expectLater(
            pending,
            throwsA(
              isA<ApiAuthException>().having(
                (error) => error.failure,
                'failure',
                ApiAuthFailure.unauthorized,
              ),
            ),
          );
          adapter.respond();
          await outcome;
          expect(session.isSignedIn, replaceSession);
          expect(
            session.revision,
            revisionBeforeResponse + (replaceSession ? 0 : 1),
          );
        },
      );
    }
  }
}
