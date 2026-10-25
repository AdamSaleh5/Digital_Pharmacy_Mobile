import 'dart:async';

typedef PushTokenRegistrationAttempt = Future<bool> Function(String token);

/// Obtains messaging registration independently of notification-display access.
/// Apple still requires its APNs transport token before an FCM request is valid.
class PushTokenAcquirer {
  const PushTokenAcquirer({required this.fetchToken, this.fetchApnsToken});

  final Future<String?> Function() fetchToken;
  final Future<String?> Function()? fetchApnsToken;

  Future<String?> call() async {
    final apns = fetchApnsToken;
    if (apns != null && (await apns())?.trim().isNotEmpty != true) return null;
    return fetchToken();
  }
}

/// Keeps the latest unregistered token in memory until an integration can
/// retry registration. A newer token replaces a stale pending token.
class PendingPushTokenRegistration {
  String? _pendingToken;
  bool _retryInProgress = false;
  int _revision = 0;

  bool get hasPendingRegistration => _pendingToken != null;

  void markPending(String token) {
    final normalized = token.trim();
    if (normalized.isNotEmpty) {
      _revision++;
      _pendingToken = normalized;
    }
  }

  /// Attempts one registration. Failure or a thrown error leaves the current
  /// token pending; success clears it only if no newer token arrived meanwhile.
  Future<bool> retry(PushTokenRegistrationAttempt attempt) async {
    final token = _pendingToken;
    if (token == null || _retryInProgress) return false;
    _retryInProgress = true;
    final revision = _revision;
    try {
      final registered = await attempt(token);
      if (registered && _revision == revision) _pendingToken = null;
      return registered;
    } catch (_) {
      return false;
    } finally {
      _retryInProgress = false;
    }
  }

  void clear() {
    _revision++;
    _pendingToken = null;
  }
}

/// Tracks the current messaging token in memory and forwards rotations.
/// The token is intentionally never persisted or logged by this class.
class PushTokenLifecycle {
  PushTokenLifecycle({
    required Future<String?> Function() fetchCurrentToken,
    required Stream<String> tokenRefreshes,
    required void Function(String token) onTokenChanged,
    this.acquisitionTimeout = const Duration(seconds: 10),
    this.retryDelays = const [
      Duration(seconds: 2),
      Duration(seconds: 10),
      Duration(seconds: 30),
    ],
  }) : _fetchCurrentToken = fetchCurrentToken,
       _tokenRefreshes = tokenRefreshes,
       _onTokenChanged = onTokenChanged;

  final Future<String?> Function() _fetchCurrentToken;
  final Stream<String> _tokenRefreshes;
  final void Function(String token) _onTokenChanged;
  final Duration acquisitionTimeout;
  final List<Duration> retryDelays;
  StreamSubscription<String>? _subscription;
  String? _currentToken;
  int _refreshRevision = 0;
  bool _disposed = false;
  int _retryIndex = 0;
  Timer? _retryTimer;
  Timer? _deadline;
  Completer<String?>? _lookup;
  Future<void>? _acquiring;

  String? get currentToken => _currentToken;

  /// One bounded cycle at startup/foreground. Refresh events remain subscribed
  /// after the retry budget is exhausted; a token is not permanent identity.
  Future<void> start() {
    if (_disposed) return Future.value();
    _subscription ??= _tokenRefreshes.listen(
      (token) {
        if (_disposed || token.trim().isEmpty) return;
        _refreshRevision++;
        _publish(token);
      },
      onError: (Object error, StackTrace stackTrace) {
        // Keep the prior token/pending association. Retry within the same budget.
        _scheduleRetry();
      },
    );
    final pending = _acquiring;
    if (pending != null) return pending;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryIndex = 0;
    return _acquire();
  }

  Future<void> _acquire() {
    final refreshBefore = _refreshRevision;
    final response = Completer<String?>();
    _lookup = response;
    final deadline = Timer(acquisitionTimeout, () {
      if (!response.isCompleted) response.complete(null);
    });
    _deadline = deadline;
    // Firebase's native Future cannot be cancelled. Its late result/error is
    // consumed but cannot publish after a deadline, refresh or disposal.
    unawaited(
      Future<String?>.sync(_fetchCurrentToken).then(
        (token) {
          if (!response.isCompleted) response.complete(token);
        },
        onError: (Object _, StackTrace __) {
          if (!response.isCompleted) response.complete(null);
        },
      ),
    );
    late final Future<void> operation;
    operation =
        (() async {
          var valid = false;
          try {
            final token = await response.future;
            if (!_disposed && refreshBefore == _refreshRevision) {
              valid = _publish(token);
            }
          } finally {
            deadline.cancel();
            if (identical(_deadline, deadline)) _deadline = null;
            if (identical(_lookup, response)) _lookup = null;
            if (identical(_acquiring, operation)) _acquiring = null;
            if (!_disposed && !valid && refreshBefore == _refreshRevision) {
              _scheduleRetry();
            }
          }
        })();
    _acquiring = operation;
    return operation;
  }

  void _scheduleRetry() {
    if (_disposed ||
        _retryTimer != null ||
        _acquiring != null ||
        _retryIndex >= retryDelays.length)
      return;
    _retryTimer = Timer(retryDelays[_retryIndex++], () {
      _retryTimer = null;
      if (!_disposed) unawaited(_acquire());
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _deadline?.cancel();
    _deadline = null;
    final lookup = _lookup;
    if (lookup != null && !lookup.isCompleted) lookup.complete(null);
    _currentToken = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  bool _publish(String? token) {
    final normalized = token?.trim();
    if (_disposed || normalized == null || normalized.isEmpty) return false;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryIndex = 0;
    if (normalized != _currentToken) {
      _currentToken = normalized;
      _onTokenChanged(normalized);
    }
    return true;
  }
}
