import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_session.dart';

import 'activation_api_adapter.dart';

export 'activation_api_adapter.dart';

abstract interface class ActivationVerifier {
  Future<ActivationVerification> verifyDevice({
    required String activationCode,
    bool? isNewUser,
    String? deviceId,
  });
}

class ActivationService implements ActivationVerifier {
  factory ActivationService.configured({
    AuthSession? session,
    Dio? dio,
    Uri? apiOrigin,
    ActivationApiAdapter adapter = const SwaggerActivationApiAdapter(),
  }) {
    final origin = apiOrigin ?? Uri.parse(ApiConfig.baseUrl);
    return ActivationService(
      dio:
          dio ??
          Dio(
            BaseOptions(
              baseUrl: origin.toString(),
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              followRedirects: false,
              headers: const {'Accept': 'application/json'},
            ),
          ),
      session: session,
      apiOrigin: origin,
      adapter: adapter,
    );
  }

  ActivationService({
    required Dio dio,
    AuthSession? session,
    required Uri apiOrigin,
    ActivationApiAdapter adapter = const SwaggerActivationApiAdapter(),
  }) : _dio = dio,
       _apiOrigin = apiOrigin,
       _adapter = adapter;

  final Dio _dio;
  final Uri _apiOrigin;
  final ActivationApiAdapter _adapter;

  /// Submits a user-entered ad-removal code to the confirmed activation API.
  ///
  /// The adapter checks the application result as well as the HTTP status.
  /// Admin authentication is never required or forwarded by this service.
  @override
  Future<ActivationVerification> verifyDevice({
    required String activationCode,
    bool? isNewUser,
    String? deviceId,
  }) async {
    final code = activationCode.trim();
    if (code.isEmpty) {
      throw ArgumentError.value(activationCode, 'activationCode');
    }
    if (!isSecureApiOrigin(_apiOrigin)) {
      throw StateError('Activation requires an HTTPS API origin.');
    }
    final path = Uri.parse(_adapter.verificationPath);
    if (path.hasScheme ||
        path.hasAuthority ||
        path.hasFragment ||
        !path.path.startsWith('/')) {
      throw StateError('Activation adapter must use a relative API path.');
    }
    final requestUri = _apiOrigin.resolveUri(path);
    if (!sameOrigin(requestUri, _apiOrigin)) {
      throw StateError(
        'Activation adapter must stay on the approved API origin.',
      );
    }
    final body = _adapter.verificationBody(
      activationCode: code,
      isNewUser: isNewUser,
      deviceId: deviceId,
    );

    final response = await _dio.postUri<dynamic>(
      requestUri,
      data: body,
      options: Options(
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        followRedirects: false,
        validateStatus: (_) => true,
      ),
    );
    if (!_adapter.handledStatusCodes.contains(response.statusCode)) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
    return _adapter.decodeVerification(
      ActivationApiReply(
        statusCode: response.statusCode,
        body: response.data,
        contentType: response.headers.value(Headers.contentTypeHeader),
      ),
    );
  }
}
