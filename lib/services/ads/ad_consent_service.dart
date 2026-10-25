import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';
import 'ads_entitlement_controller.dart';

abstract interface class AdConsentGateway {
  Future<void> requestUpdate();
  Future<void> showRequiredForm();
  Future<void> showPrivacyOptions();
  Future<bool> canRequestAds();
  Future<bool> privacyOptionsRequired();
}

/// Explicit SDK testing only. Release builds always use real SDK geography.
@visibleForTesting
ConsentRequestParameters umpRequestParameters({
  required bool debugBuild,
  required bool forceEea,
  required String testDeviceId,
}) {
  if (!debugBuild || !forceEea) return ConsentRequestParameters();
  if (!RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(testDeviceId)) {
    throw ArgumentError(
      'UMP testing requires a hashed test-device identifier.',
    );
  }
  return ConsentRequestParameters(
    consentDebugSettings: ConsentDebugSettings(
      debugGeography: DebugGeography.debugGeographyEea,
      testIdentifiers: [testDeviceId],
    ),
  );
}

class AdConsentService extends ChangeNotifier {
  AdConsentService({
    required AdConsentGateway gateway,
    required Future<void> Function() initializeAds,
    required bool Function() isSupported,
    bool autoStartOnFree = false,
  }) : _gateway = gateway,
       _initializeAds = initializeAds,
       _isSupported = isSupported,
       _autoStartOnFree = autoStartOnFree {
    _lastEntitlement = AdsEntitlementController.instance.state;
    if (autoStartOnFree)
      AdsEntitlementController.instance.addListener(_onEntitlementChanged);
  }

  static final instance = AdConsentService(
    gateway: _UmpGateway(),
    initializeAds: () async {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
      );
      await MobileAds.instance.initialize();
    },
    isSupported: () => AdService.isSupportedPlatform,
    autoStartOnFree: true,
  );

  final AdConsentGateway _gateway;
  final Future<void> Function() _initializeAds;
  final bool Function() _isSupported;
  final bool _autoStartOnFree;
  late AdsEntitlementState _lastEntitlement;
  bool _disposed = false;
  Future<void>? _gathering;
  bool _initializedAds = false;
  Future<void>? _initializingAds;
  int _permissionRevision = 0;
  bool _privacyOptionsRequired = false;
  bool _showingPrivacyOptions = false;
  bool get privacyOptionsRequired => _privacyOptionsRequired;
  bool get showingPrivacyOptions => _showingPrivacyOptions;

  Future<void> gatherConsent() {
    if (_disposed || _showingPrivacyOptions || !_isSupported())
      return Future.value();
    if (!AdsEntitlementController.instance.adsAllowed) return Future.value();
    return _gathering ??= _gather().whenComplete(() => _gathering = null);
  }

  void _onEntitlementChanged() {
    final controller = AdsEntitlementController.instance;
    final previous = _lastEntitlement;
    _lastEntitlement = controller.state;
    if (!controller.adsAllowed) {
      controller.setPrivacyPermission(false);
    } else if (previous != AdsEntitlementState.free) {
      unawaited(gatherConsent());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _permissionRevision++;
    if (_autoStartOnFree)
      AdsEntitlementController.instance.removeListener(_onEntitlementChanged);
    super.dispose();
  }

  Future<void> _gather() async {
    final revision = ++_permissionRevision;
    AdsEntitlementController.instance.setPrivacyPermission(false);
    try {
      await _gateway.requestUpdate();
      await _gateway.showRequiredForm();
    } catch (_) {
      // Only UMP may decide whether a previous SDK consent still permits ads.
    }
    await _refreshPermission(revision);
  }

  Future<void> _refreshPermission(int revision) async {
    bool current() => !_disposed && revision == _permissionRevision;
    if (!current()) return;
    var allowed = false;
    try {
      allowed = await _gateway.canRequestAds();
      final optionsRequired = await _gateway.privacyOptionsRequired();
      if (!current()) return;
      _privacyOptionsRequired = optionsRequired;
      if (allowed &&
          AdsEntitlementController.instance.adsAllowed &&
          !_showingPrivacyOptions &&
          !_initializedAds) {
        await (_initializingAds ??= Future<void>.sync(_initializeAds)
            .then((_) => _initializedAds = true)
            .whenComplete(() => _initializingAds = null));
      }
    } catch (_) {
      allowed = false;
    }
    if (!current()) return;
    AdsEntitlementController.instance.setPrivacyPermission(
      allowed && _initializedAds && !_showingPrivacyOptions,
    );
    if (kDebugMode) {
      debugPrint(
        '[UMP] canRequestAds=${AdsEntitlementController.instance.canRequestAds} '
        'optionsRequired=$_privacyOptionsRequired',
      );
    }
    notifyListeners();
  }

  Future<void> showPrivacyOptions() async {
    if (_disposed ||
        !_isSupported() ||
        !_privacyOptionsRequired ||
        _showingPrivacyOptions) {
      return;
    }
    final revision = ++_permissionRevision;
    _showingPrivacyOptions = true;
    AdsEntitlementController.instance.setPrivacyPermission(false);
    notifyListeners();
    try {
      await _gateway.showPrivacyOptions();
    } catch (_) {
      // Restore permission only from the SDK's current result after dismissal.
    } finally {
      _showingPrivacyOptions = false;
      await _refreshPermission(revision);
    }
  }
}

class _UmpGateway implements AdConsentGateway {
  bool _testResetDone = false;

  @override
  Future<void> requestUpdate() async {
    // Opt-in defines are used only on the isolated local test AVD. Never reset
    // consent automatically in ordinary debug or release builds.
    if (kDebugMode &&
        const bool.fromEnvironment('UMP_DEBUG_RESET') &&
        !_testResetDone) {
      await ConsentInformation.instance.reset();
      _testResetDone = true;
      debugPrint('[UMP] test-only SDK reset');
    }
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      umpRequestParameters(
        debugBuild: kDebugMode,
        forceEea: const bool.fromEnvironment('UMP_DEBUG_EEA'),
        testDeviceId: const String.fromEnvironment('UMP_DEBUG_DEVICE'),
      ),
      () {
        if (kDebugMode) debugPrint('[UMP] update.succeeded');
        completer.complete();
      },
      (error) {
        if (kDebugMode) {
          debugPrint('[UMP] update.failed code=${error.errorCode}');
        }
        completer.completeError(error);
      },
    );
    return completer.future;
  }

  Future<void> _show(
    Future<void> Function(OnConsentFormDismissedListener) present,
  ) async {
    FormError? failure;
    await present((error) => failure = error);
    if (failure != null) throw failure!;
  }

  @override
  Future<void> showRequiredForm() =>
      _show(ConsentForm.loadAndShowConsentFormIfRequired);

  @override
  Future<void> showPrivacyOptions() =>
      _show(ConsentForm.showPrivacyOptionsForm);

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;
}
