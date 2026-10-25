import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/store_entitlement_policy.dart';
import '../../../core/network/activation_service.dart';
import '../../../core/network/auth_session.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/soft_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_provider.dart';
import '../../../services/ads/activation_coordinator.dart';
import '../../../services/ads/activation_entitlement_restorer.dart';
import '../../../services/ads/ads_entitlement_controller.dart';
import '../../../services/notifications/push_notification_service.dart';

enum _ActivationUiState {
  idle,
  submitting,
  confirmed,
  unconfirmed,
  rejected,
  notSaved,
  failed,
  codeRequired,
  deviceUnavailable,
}

class ActivationPage extends StatefulWidget {
  const ActivationPage({
    super.key,
    this.verifier,
    this.session,
    this.apiOrigin,
    this.restorer,
    this.isNewUser,
    this.deviceId,
    this.deviceTokenProvider,
  });

  final ActivationVerifier? verifier;
  final AuthSession? session;
  final Uri? apiOrigin;
  final ActivationEntitlementRestorer? restorer;

  /// Optional explicit context for embedded callers. Ordinary navigation uses
  /// saved installation state and obtains the current Firebase FCM token.
  final bool? isNewUser;
  final String? deviceId;
  final Future<String?> Function()? deviceTokenProvider;

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _codeController = TextEditingController();
  late final ActivationVerifier _verifier;
  late final ActivationCoordinator _coordinator;
  ActivationEntitlementRestorer? _restorer;
  _ActivationUiState _result = _ActivationUiState.idle;
  int _submissionRevision = 0;

  Uri get _apiOrigin => widget.apiOrigin ?? Uri.parse(ApiConfig.baseUrl);
  bool get _transportAllowed => isAllowedAuthOrigin(_apiOrigin);

  @override
  void initState() {
    super.initState();
    final app = Provider.of<AppProvider?>(context, listen: false);
    _restorer = widget.restorer ?? app?.activationRestorer;
    _verifier =
        widget.verifier ??
        ActivationService.configured(
          apiOrigin: _apiOrigin,
          adapter:
              app?.activationAdapter ?? const SwaggerActivationApiAdapter(),
        );
    _coordinator = ActivationCoordinator(
      verifier: _verifier,
      restorer: _restorer,
    );
    AdsEntitlementController.instance.addListener(_onEntitlementChanged);
    if (_alreadyActivated) _result = _ActivationUiState.confirmed;
  }

  bool get _alreadyActivated =>
      _restorer?.hasSavedActivation == true &&
      AdsEntitlementController.instance.state ==
          AdsEntitlementState.confirmedAdFree;

  void _onEntitlementChanged() {
    if (!mounted) return;
    setState(() {
      if (_alreadyActivated) {
        _result = _ActivationUiState.confirmed;
      } else if (_result == _ActivationUiState.confirmed) {
        _result = _ActivationUiState.idle;
      }
    });
  }

  @override
  void didUpdateWidget(covariant ActivationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isNewUser != widget.isNewUser ||
        oldWidget.deviceId != widget.deviceId) {
      _coordinator.invalidatePendingSubmission();
      _submissionRevision++;
      _codeController.clear();
      _result = _ActivationUiState.idle;
    }
  }

  @override
  void dispose() {
    AdsEntitlementController.instance.removeListener(_onEntitlementChanged);
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || _alreadyActivated) return;
    FocusScope.of(context).unfocus();
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _result = _ActivationUiState.codeRequired);
      return;
    }
    if (!_transportAllowed) {
      setState(() => _result = _ActivationUiState.failed);
      return;
    }

    _codeController.clear();
    final revision = ++_submissionRevision;
    setState(() => _result = _ActivationUiState.submitting);
    try {
      final deviceId =
          widget.deviceId?.trim() ??
          (await (widget.deviceTokenProvider ??
                  PushNotificationService.activationDeviceToken)())
              ?.trim();
      if (!mounted || revision != _submissionRevision) return;
      if (deviceId == null || deviceId.isEmpty) {
        setState(() => _result = _ActivationUiState.deviceUnavailable);
        return;
      }
      final result = await _coordinator.submit(
        code,
        isNewUser:
            widget.isNewUser ?? !(_restorer?.hasSavedActivation ?? false),
        deviceId: deviceId,
      );
      if (!mounted || revision != _submissionRevision) return;
      setState(
        () =>
            _result = switch (result) {
              ActivationSubmission.confirmed => _ActivationUiState.confirmed,
              ActivationSubmission.rejected => _ActivationUiState.rejected,
              ActivationSubmission.unconfirmed =>
                _ActivationUiState.unconfirmed,
              ActivationSubmission.notSaved => _ActivationUiState.notSaved,
              ActivationSubmission.superseded => _ActivationUiState.idle,
            },
      );
    } catch (_) {
      if (!mounted || revision != _submissionRevision) return;
      setState(() => _result = _ActivationUiState.failed);
    }
  }

  String? _message(AppLocalizations l10n) => switch (_result) {
    _ActivationUiState.idle => null,
    _ActivationUiState.submitting => l10n.activationChecking,
    _ActivationUiState.confirmed => l10n.activationConfirmed,
    _ActivationUiState.notSaved => l10n.activationNotSaved,
    _ActivationUiState.unconfirmed => l10n.activationUnconfirmed,
    _ActivationUiState.rejected => l10n.activationRejected,
    _ActivationUiState.failed => l10n.activationVerificationFailed,
    _ActivationUiState.codeRequired => l10n.activationCodeRequired,
    _ActivationUiState.deviceUnavailable => l10n.activationDeviceUnavailable,
  };

  Color _messageColor(BuildContext context) => switch (_result) {
    _ActivationUiState.unconfirmed ||
    _ActivationUiState.notSaved => Theme.of(context).colorScheme.tertiary,
    _ActivationUiState.failed ||
    _ActivationUiState.rejected ||
    _ActivationUiState.deviceUnavailable ||
    _ActivationUiState.codeRequired => Theme.of(context).colorScheme.error,
    _ActivationUiState.confirmed ||
    _ActivationUiState.idle ||
    _ActivationUiState
        .submitting => Theme.of(context).colorScheme.onSurfaceVariant,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!supportsCustomActivationCode) {
      return Scaffold(
        appBar: AppHeader(title: l10n.activationTitle),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.storeEntitlementUnavailable),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final statusMessage = _message(l10n);

    return Scaffold(
      appBar: AppHeader(title: l10n.activationTitle),
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.activationDescription,
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (!_transportAllowed && !_alreadyActivated) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.activationHttpRiskNotice,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 18),
                      TextField(
                        controller: _codeController,
                        enabled:
                            _transportAllowed &&
                            !_isSubmitting &&
                            !_alreadyActivated,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: l10n.activationCodeLabel,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) {
                          if (_result == _ActivationUiState.codeRequired) {
                            setState(() => _result = _ActivationUiState.idle);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed:
                            _isSubmitting ||
                                    !_transportAllowed ||
                                    _alreadyActivated
                                ? null
                                : _submit,
                        icon:
                            _isSubmitting
                                ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.verified_outlined),
                        label: Text(
                          _isSubmitting
                              ? l10n.activationChecking
                              : l10n.activationSubmit,
                        ),
                      ),
                      if (statusMessage != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            statusMessage,
                            style: TextStyle(color: _messageColor(context)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _isSubmitting => _result == _ActivationUiState.submitting;
}
