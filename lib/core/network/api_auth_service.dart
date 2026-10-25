import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_session.dart';

enum ApiAuthFailure { httpsRequired, unauthorized, invalidToken, requestFailed }

class ApiAuthException implements Exception {
  const ApiAuthException(this.failure);

  final ApiAuthFailure failure;
}

/// Legacy admin login requires verified HTTPS. Tokens remain in memory.
class ApiAuthService {
  ApiAuthService({
    String? baseUrl,
    String? verifiedOrigin,
    AuthSession? session,
    Dio? dio,
  }) : _baseUri = _tryParseOrigin(baseUrl ?? ApiConfig.baseUrl),
       _verifiedOrigin = _tryParseOrigin(
         verifiedOrigin ?? ApiConfig.verifiedAuthOrigin,
       ),
       session = session ?? AuthSession.shared,
       _dio = dio ?? _createDio(baseUrl ?? ApiConfig.baseUrl);

  final Uri? _baseUri;
  final Uri? _verifiedOrigin;
  final Dio _dio;
  final AuthSession session;
  int _loginAttempt = 0;

  bool get isHttpsConfigured =>
      isSecureApiOrigin(_baseUri) &&
      isSecureApiOrigin(_verifiedOrigin) &&
      sameOrigin(_baseUri, _verifiedOrigin);

  bool get isSignInConfigured => isHttpsConfigured;

  bool get usesInsecureHttp => isApprovedHttpApiOrigin(_baseUri);

  Future<void> login({required String email, required String password}) async {
    final configuredOrigin = _baseUri;
    final verifiedOrigin = _verifiedOrigin;
    if (!isSignInConfigured || configuredOrigin == null) {
      throw const ApiAuthException(ApiAuthFailure.httpsRequired);
    }
    final origin = isHttpsConfigured ? verifiedOrigin! : configuredOrigin;
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const ApiAuthException(ApiAuthFailure.requestFailed);
    }

    final loginUri = origin.resolve('/api/auth/login');
    final requestRevision = session.revision;
    final attempt = ++_loginAttempt;
    try {
      final response = await _dio.postUri<dynamic>(
        loginUri,
        data: {'email': normalizedEmail, 'password': password},
        options: Options(
          contentType: Headers.jsonContentType,
          headers: const {'Accept': 'application/json'},
          followRedirects: false,
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode == 401) {
        if (attempt == _loginAttempt) {
          session.handleUnauthorized(
            requestUri: loginUri,
            configuredApiOrigin: origin,
            requestRevision: requestRevision,
          );
        }
        throw const ApiAuthException(ApiAuthFailure.unauthorized);
      }
      // A completed login belongs to the intent and session that started it.
      // Logout, a later submission or a replacement session makes it obsolete.
      if (attempt != _loginAttempt || session.revision != requestRevision) {
        throw const ApiAuthException(ApiAuthFailure.requestFailed);
      }
      if (response.statusCode != 200) {
        throw const ApiAuthException(ApiAuthFailure.requestFailed);
      }
      final data = response.data;
      final rawToken = data is Map ? data['accessToken'] : null;
      if (rawToken is! String || rawToken.trim().isEmpty) {
        session.signOut();
        throw const ApiAuthException(ApiAuthFailure.invalidToken);
      }
      session.start(accessToken: rawToken, apiOrigin: origin);
    } on ApiAuthException {
      rethrow;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        if (attempt == _loginAttempt) {
          session.handleUnauthorized(
            requestUri: loginUri,
            configuredApiOrigin: origin,
            requestRevision: requestRevision,
          );
        }
        throw const ApiAuthException(ApiAuthFailure.unauthorized);
      }
      throw const ApiAuthException(ApiAuthFailure.requestFailed);
    } catch (_) {
      throw const ApiAuthException(ApiAuthFailure.requestFailed);
    }
  }

  void logout() {
    // Invalidates a pending first login even while the session is anonymous.
    _loginAttempt++;
    session.signOut();
  }

  static Uri? _tryParseOrigin(String value) {
    final uri = Uri.tryParse(value);
    if (!isAllowedAuthOrigin(uri) && !isApprovedHttpApiOrigin(uri)) return null;
    return uri;
  }

  static Dio _createDio(String baseUrl) => Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: false,
      headers: const {'Accept': 'application/json'},
    ),
  );
}
