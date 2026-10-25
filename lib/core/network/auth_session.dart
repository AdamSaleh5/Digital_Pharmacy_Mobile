import 'package:flutter/foundation.dart';

/// Keeps an access token in memory for the current process only.
class AuthSession extends ChangeNotifier {
  AuthSession();

  static final AuthSession shared = AuthSession();

  String? _accessToken;
  Uri? _apiOrigin;
  int _revision = 0;

  bool get isSignedIn => _accessToken != null;
  int get revision => _revision;

  void start({required String accessToken, required Uri apiOrigin}) {
    final token = accessToken.trim();
    if (token.isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'must not be empty',
      );
    }
    if (!isAllowedAuthOrigin(apiOrigin)) {
      throw ArgumentError.value(apiOrigin, 'apiOrigin', 'must use HTTPS');
    }
    _accessToken = token;
    _apiOrigin = apiOrigin;
    _revision++;
    notifyListeners();
  }

  void signOut() {
    if (_accessToken == null && _apiOrigin == null) return;
    _accessToken = null;
    _apiOrigin = null;
    _revision++;
    notifyListeners();
  }

  /// Returns Authorization only for the exact verified/approved API origin.
  String? authorizationFor({
    required Uri requestUri,
    required Uri? configuredApiOrigin,
  }) {
    final token = _accessToken;
    final sessionOrigin = _apiOrigin;
    if (token == null || sessionOrigin == null || configuredApiOrigin == null) {
      return null;
    }
    if (!isAllowedAuthOrigin(configuredApiOrigin) ||
        !sameOrigin(sessionOrigin, configuredApiOrigin) ||
        !sameOrigin(requestUri, configuredApiOrigin)) {
      return null;
    }
    return 'Bearer $token';
  }

  void handleUnauthorized({
    required Uri requestUri,
    required Uri? configuredApiOrigin,
    required int requestRevision,
  }) {
    // A response belongs to the session that dispatched its request, even
    // when a replacement session uses the same origin or token value.
    if (requestRevision != _revision ||
        configuredApiOrigin == null ||
        !sameOrigin(requestUri, configuredApiOrigin) ||
        !sameOrigin(_apiOrigin, configuredApiOrigin)) {
      return;
    }
    signOut();
  }
}

bool isSecureApiOrigin(Uri? uri) =>
    uri != null &&
    uri.scheme.toLowerCase() == 'https' &&
    uri.host.isNotEmpty &&
    uri.userInfo.isEmpty &&
    !uri.hasQuery &&
    !uri.hasFragment;

bool isApprovedHttpApiOrigin(Uri? uri) =>
    uri != null &&
    uri.scheme.toLowerCase() == 'http' &&
    uri.host == '144.91.111.63' &&
    uri.port == 5002 &&
    uri.userInfo.isEmpty &&
    (uri.path.isEmpty || uri.path == '/') &&
    !uri.hasQuery &&
    !uri.hasFragment;

bool isAllowedAuthOrigin(Uri? uri) => isSecureApiOrigin(uri);

bool sameOrigin(Uri? left, Uri? right) =>
    left != null &&
    right != null &&
    left.scheme.toLowerCase() == right.scheme.toLowerCase() &&
    left.host.toLowerCase() == right.host.toLowerCase() &&
    left.port == right.port &&
    left.userInfo.isEmpty &&
    right.userInfo.isEmpty;
