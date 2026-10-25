import '../../core/entitlements/ad_entitlement.dart';
import '../../core/network/activation_service.dart';
import '../../core/network/auth_session.dart';
import 'activation_entitlement_restorer.dart';
import 'ads_entitlement_controller.dart';

enum ActivationSubmission {
  confirmed,
  rejected,
  unconfirmed,
  superseded,
  notSaved,
}

/// Client transaction after an explicit server acknowledgment. This class
/// decodes no JSON and never treats HTTP200, a code or an FCM token as active.
class ActivationCoordinator {
  ActivationCoordinator({required this.verifier, this.session, this.restorer});
  final ActivationVerifier verifier;
  final AuthSession?
  session; // Legacy constructor compatibility; never an app gate.
  final ActivationEntitlementRestorer? restorer;
  int _attempt = 0;
  Future<ActivationSubmission>? _pending;
  String? _pendingCode;
  int? _pendingRevision;
  bool? _pendingIsNewUser;
  String? _pendingDeviceId;

  /// A caller changed the explicitly supplied binding while verification was
  /// in flight. Reject that old result without clearing saved entitlement.
  void invalidatePendingSubmission() {
    if (_pending == null) return;
    _attempt++;
    restorer?.beginVerification();
    _pending = null;
    _pendingCode = null;
    _pendingRevision = null;
    _pendingIsNewUser = null;
    _pendingDeviceId = null;
  }

  /// The app supplies isNewUser from saved activation state and deviceId from
  /// the current FCM token, as specified by the project owner. Neither the code
  /// nor the token is persisted by this coordinator.
  Future<ActivationSubmission> submit(
    String code, {
    bool? isNewUser,
    String? deviceId,
  }) {
    final normalized = code.trim();
    if (_pending != null &&
        _pendingCode == normalized &&
        _pendingIsNewUser == isNewUser &&
        _pendingDeviceId == deviceId &&
        _pendingRevision == restorer?.verificationRevision) {
      return _pending!;
    }
    late final Future<ActivationSubmission> result;
    result = _submitOnce(
      normalized,
      isNewUser: isNewUser,
      deviceId: deviceId,
    ).whenComplete(() {
      if (identical(_pending, result)) {
        _pending = null;
        _pendingCode = null;
        _pendingRevision = null;
        _pendingIsNewUser = null;
        _pendingDeviceId = null;
      }
    });
    _pendingCode = normalized; // In-flight only; never persisted or logged.
    _pendingIsNewUser = isNewUser;
    _pendingDeviceId = deviceId;
    _pendingRevision = restorer?.verificationRevision;
    _pending = result;
    return result;
  }

  Future<ActivationSubmission> _submitOnce(
    String code, {
    bool? isNewUser,
    String? deviceId,
  }) async {
    final attempt = ++_attempt;
    final ticket = restorer?.beginVerification();
    bool current() =>
        attempt == _attempt &&
        (ticket == null || restorer!.acceptsVerification(ticket));
    final result = await verifier.verifyDevice(
      activationCode: code.trim(),
      isNewUser: isNewUser,
      deviceId: deviceId,
    );
    if (!current()) return ActivationSubmission.superseded;
    if (result.isRejected) return ActivationSubmission.rejected;
    if (!result.isConfirmedActive) return ActivationSubmission.unconfirmed;
    final store = restorer;
    if (store == null) {
      AdsEntitlementController.instance.beginRestoration();
      return ActivationSubmission.notSaved;
    }
    if (store.isDisposed) return ActivationSubmission.superseded;
    // Resolve starts suppression synchronously, before the persistence await.
    final applied = await store.resolve(
      result.confirmedScope!,
      (_) async => EntitlementStatus.active,
    );
    if (!current()) return ActivationSubmission.superseded;
    return applied
        ? ActivationSubmission.confirmed
        : ActivationSubmission.notSaved;
  }
}
