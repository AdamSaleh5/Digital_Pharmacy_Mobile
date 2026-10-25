import 'package:shared_preferences/shared_preferences.dart';

import '../../core/entitlements/ad_entitlement.dart';
import 'ads_entitlement_controller.dart';

/// Optional server lookup hook; the ordinary app restores local confirmation.
typedef EntitlementLookup = Future<EntitlementStatus> Function(String scope);

/// Persists a successful activation until app data is cleared. A subsequent
/// launch needs no network, admin session, code or original FCM token.
class ActivationEntitlementRestorer {
  ActivationEntitlementRestorer({required this.preferences, required this.ads});

  static const historyKey = 'activation_confirmation_scope_v1';
  final SharedPreferences preferences;
  final AdsEntitlementController ads;
  String? _scope;
  String? _savedScope;
  bool _hasSavedActivation = false;
  int _revision = 0;
  int _verificationRevision = 0;
  int get verificationRevision => _verificationRevision;

  int beginVerification() {
    invalidateOutstandingLookup();
    return ++_verificationRevision;
  }

  bool acceptsVerification(int ticket) =>
      !_disposed && ticket == _verificationRevision;
  Future<void> _storageTail = Future.value();
  bool _disposed = false;
  bool get isDisposed => _disposed;

  String? get confirmationScope => _scope;
  bool get hasSavedActivation => _hasSavedActivation;

  void bootstrap() {
    _scope = preferences.getString(historyKey);
    _hasSavedActivation = _scope?.trim().isNotEmpty == true;
    _savedScope = _hasSavedActivation ? _scope : null;
    if (hasSavedActivation) {
      ads.setConfirmedAdFree();
    }
  }

  void invalidateOutstandingLookup() => _revision++;

  Future<bool> resolve(String scope, EntitlementLookup lookup) async {
    if (_disposed) return false;
    if (scope.trim().isEmpty) throw ArgumentError('Scope must not be empty.');
    final revision = ++_revision;
    _scope = scope;
    ads.beginRestoration();
    EntitlementStatus status;
    try {
      status = await lookup(scope);
    } catch (_) {
      // Offline or ambiguous: leave restoration pending without ad flashes.
      return false;
    }
    if (revision != _revision || _scope != scope) return false;
    try {
      switch (status) {
        case EntitlementStatus.active:
          // Only an explicit positive activation result reaches this write.
          return await _serialize(() async {
            if (revision != _revision || _scope != scope) return false;
            bool saved;
            try {
              saved = await preferences.setString(historyKey, scope);
            } catch (_) {
              await _repairSavedMarker();
              return false;
            }
            if (!saved || revision != _revision || _scope != scope) {
              await _repairSavedMarker();
              return false;
            }
            _savedScope = scope;
            _hasSavedActivation = true;
            ads.setConfirmedAdFree();
            return true;
          });
        case EntitlementStatus.inactive:
          return await _serialize(() async {
            if (revision != _revision || _scope != scope) return false;
            bool removed;
            try {
              removed = await preferences.remove(historyKey);
            } catch (_) {
              await _repairSavedMarker();
              return false;
            }
            if (!removed || revision != _revision || _scope != scope) {
              await _repairSavedMarker();
              return false;
            }
            _scope = null;
            _savedScope = null;
            _hasSavedActivation = false;
            ads.setFree();
            return true;
          });
        case EntitlementStatus.unknown:
          return false;
      }
    } catch (_) {
      // A failed local write must not grant active or crash background restore.
      return false;
    }
  }

  Future<bool> restore(EntitlementLookup lookup) async {
    final scope = _scope;
    if (scope == null || scope.isEmpty) return false;
    return resolve(scope, lookup);
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _storageTail.then((_) => operation());
    _storageTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  /// Called inside the storage queue after an unsuccessful or obsolete write.
  /// SharedPreferences changes its cache before the platform write completes;
  /// repair both cache and disk before another restorer can bootstrap from it.
  /// Use the latest committed value so an explicit clear cannot be undone.
  Future<void> _repairSavedMarker() async {
    try {
      final savedScope = _savedScope;
      if (savedScope == null) {
        await preferences.remove(historyKey);
      } else {
        await preferences.setString(historyKey, savedScope);
      }
    } catch (_) {
      // The cache has still been restored by the legacy preferences API. A
      // platform failure leaves durability uncertain; never report success.
    }
  }

  /// Explicit installation binding reset only; never admin logout or token refresh.
  Future<void> clear() async {
    if (_disposed) return;
    _revision++;
    _verificationRevision++;
    _scope = null;
    _savedScope = null;
    _hasSavedActivation = false;
    ads.setFree();
    try {
      await _serialize(() => preferences.remove(historyKey));
    } catch (_) {
      // A surviving saved confirmation continues to suppress ads on relaunch.
    }
  }

  void dispose() {
    _disposed = true;
    _verificationRevision++;
    invalidateOutstandingLookup();
  }
}
