import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_session.dart';

const _authorizationHeader = 'Authorization';
const _sessionRevisionExtra = 'apiAuthSessionRevision';
const _authenticatedRequestExtra = 'apiAuthenticatedRequest';

/// Read-only Dio transport used by the documented API operations.
class ApiTransport {
  ApiTransport({
    Dio? dio,
    AuthSession? authSession,
    String? baseUrl,
    String? verifiedOrigin,
  }) : dio = dio ?? Dio(_options(baseUrl ?? ApiConfig.baseUrl)),
       _authSession = authSession,
       _apiOrigin = _verifiedOrigin(
         baseUrl ?? ApiConfig.baseUrl,
         verifiedOrigin ?? ApiConfig.verifiedAuthOrigin,
       ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Never forward caller-supplied auth to an arbitrary URL or redirect.
          final authorizationKeys =
              options.headers.keys
                  .where((key) => key.toLowerCase() == 'authorization')
                  .toList();
          for (final key in authorizationKeys) {
            options.headers.remove(key);
          }
          final authorization = _authSession?.authorizationFor(
            requestUri: options.uri,
            configuredApiOrigin: _apiOrigin,
          );
          options.extra[_authenticatedRequestExtra] = authorization != null;
          options.extra[_sessionRevisionExtra] = (_authSession?.revision ?? 0);
          if (authorization != null) {
            options.headers[_authorizationHeader] = authorization;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.statusCode == 401) {
            _clearSessionFor(response.requestOptions);
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _clearSessionFor(error.requestOptions);
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final AuthSession? _authSession;
  final Uri? _apiOrigin;

  bool get hasAuthorizedSession =>
      _apiOrigin != null &&
      _authSession?.authorizationFor(
            requestUri: _apiOrigin,
            configuredApiOrigin: _apiOrigin,
          ) !=
          null;

  static BaseOptions _options(String baseUrl) => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    followRedirects: false,
    headers: const {'Accept': 'application/json'},
  );

  static Uri? _verifiedOrigin(String baseUrl, String verifiedOrigin) {
    final base = Uri.tryParse(baseUrl);
    final verified = Uri.tryParse(verifiedOrigin);
    if (!isSecureApiOrigin(base) ||
        !isSecureApiOrigin(verified) ||
        !sameOrigin(base, verified)) {
      return null;
    }
    return verified;
  }

  void _clearSessionFor(RequestOptions request) {
    if (request.extra[_authenticatedRequestExtra] != true) return;
    final requestRevision = request.extra[_sessionRevisionExtra];
    if (requestRevision is! int) return;
    _authSession?.handleUnauthorized(
      requestUri: request.uri,
      configuredApiOrigin: _apiOrigin,
      requestRevision: requestRevision,
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    final query = queryParameters?.map(
      (key, value) => MapEntry(key, value is String ? value.trim() : value),
    );
    try {
      final response = await dio.get<T>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(followRedirects: false),
      );
      if (response.statusCode == 401) {
        _clearSessionFor(response.requestOptions);
      } else {
        _rejectStaleAuthenticatedResponse(response.requestOptions);
      }
      return response;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        _clearSessionFor(error.requestOptions);
        rethrow;
      }
      _rejectStaleAuthenticatedResponse(error.requestOptions);
      rethrow;
    }
  }

  void _rejectStaleAuthenticatedResponse(RequestOptions request) {
    if (request.extra[_authenticatedRequestExtra] != true) return;
    final requestRevision = request.extra[_sessionRevisionExtra];
    if (requestRevision == (_authSession?.revision ?? 0)) return;
    throw DioException(
      requestOptions: request,
      type: DioExceptionType.cancel,
      message: 'Authenticated response discarded after session change.',
    );
  }
}
