import 'package:flutter/foundation.dart';

import '../../core/entitlements/ad_entitlement.dart';

/// A positive server activation or its saved local confirmation disables ads.
/// Unknown suppresses ads while a confirmation is being saved or resolved.
enum AdsEntitlementState { restorationPending, free, confirmedAdFree }

class AdsEntitlementController extends ChangeNotifier
    implements AdEntitlementReader {
  AdsEntitlementController._();

  static final AdsEntitlementController instance = AdsEntitlementController._();

  // No saved activation history is the normal ads-on state. Restoration is
  // reserved for an explicit restoration that is still waiting on the server.
  AdsEntitlementState _state = AdsEntitlementState.free;
  final ValueNotifier<AdEntitlementSnapshot> _snapshot = ValueNotifier(
    const AdEntitlementSnapshot(EntitlementStatus.inactive),
  );

  AdsEntitlementState get state => _state;
  bool get adsAllowed => _state == AdsEntitlementState.free;
  bool _privacyPermission = false;
  bool get canRequestAds => adsAllowed && _privacyPermission;

  /// SDK permission is refreshed by UMP each launch, never from an app cache.
  void setPrivacyPermission(bool allowed) {
    if (_privacyPermission == allowed) return;
    _privacyPermission = allowed;
    notifyListeners();
  }

  @override
  ValueListenable<AdEntitlementSnapshot> get adEntitlement => _snapshot;

  /// Use for users with no activation history or a server-resolved inactive
  /// activation. This is the default state for a fresh installation.
  void setFree() => _set(AdsEntitlementState.free);

  /// Call only after the server confirms an active activation entitlement.
  void setConfirmedAdFree() => _set(AdsEntitlementState.confirmedAdFree);

  /// Call only when restoring a known previous activation and the server must
  /// resolve whether it is still active. Ads stay suppressed while pending.
  void beginRestoration() => _set(AdsEntitlementState.restorationPending);

  /// Explicitly marks entitlement restoration as pending. Ads stay suppressed
  /// until a server-backed result resolves the state.
  void _set(AdsEntitlementState value) {
    if (_state == value) return;
    _state = value;
    _snapshot.value = AdEntitlementSnapshot(switch (value) {
      AdsEntitlementState.restorationPending => EntitlementStatus.unknown,
      AdsEntitlementState.free => EntitlementStatus.inactive,
      AdsEntitlementState.confirmedAdFree => EntitlementStatus.active,
    });
    notifyListeners();
  }
}

/// Invalidates in-flight ad load completions across every entitlement change.
class AdLoadGate {
  AdLoadGate(this.controller) {
    controller.addListener(_onEntitlementChanged);
  }

  final AdsEntitlementController controller;
  int _revision = 0;

  int beginAttempt() => _revision;

  bool accepts(int revision) =>
      revision == _revision && controller.canRequestAds;

  void invalidate() => _revision++;

  void _onEntitlementChanged() => invalidate();

  void dispose() => controller.removeListener(_onEntitlementChanged);
}

/// Consumes the launch opportunity immediately; an unready ad must never
/// appear later over a dialog, search, or another user interaction.
class LaunchAdOpportunity {
  bool _consumed = false;

  bool take({required bool adsAllowed, required bool adReady}) {
    if (_consumed) return false;
    _consumed = true;
    return adsAllowed && adReady;
  }

  void cancel() => _consumed = true;
}
