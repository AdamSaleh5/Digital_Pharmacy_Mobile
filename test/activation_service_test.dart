import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const apiOrigin = 'https://api.example.test';

  test('synthetic verify request does not infer entitlement from 200', () async {
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-bearer',
          apiOrigin: Uri.parse(apiOrigin),
        );
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: apiOrigin));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              // Even undocumented/malformed content must not activate ads-off.
              data: {'active': true, 'expiresAt': 'synthetic'},
            ),
          );
        },
      ),
    );
    final service = ActivationService(
      dio: dio,
      session: session,
      apiOrigin: Uri.parse(apiOrigin),
    );

    final result = await service.verifyDevice(
      activationCode: ' synthetic-code ',
    );

    expect(result, ActivationVerification.unconfirmed);
    expect(requests.single.uri.path, '/api/users/verify-device');
    expect(requests.single.data, {'activationCode': 'synthetic-code'});
    expect(requests.single.headers['Authorization'], isNull);
    expect(requests.single.followRedirects, isFalse);
    session.signOut();
    expect(session.isSignedIn, isFalse);
  });

  for (final httpOrigin in [
    'http://144.91.111.63:5002',
    'http://example.test:5002',
  ]) {
    test('verification refuses HTTP before dispatch: $httpOrigin', () async {
      final requests = <RequestOptions>[];
      final session = AuthSession();
      final dio = Dio();
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
      final service = ActivationService(
        dio: dio,
        session: session,
        apiOrigin: Uri.parse(httpOrigin),
      );

      await expectLater(
        service.verifyDevice(activationCode: 'synthetic-code'),
        throwsStateError,
      );
      expect(requests, isEmpty);
    });
  }
}
