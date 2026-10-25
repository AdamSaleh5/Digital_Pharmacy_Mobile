import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/notifications/push_notification_service.dart';

class NotificationSettingsSection extends StatefulWidget {
  const NotificationSettingsSection({
    super.key,
    this.readPermissionStatus,
    this.requestPermission,
  });

  final Future<PushPermissionStatus> Function()? readPermissionStatus;
  final Future<PushPermissionStatus> Function()? requestPermission;

  @override
  State<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<NotificationSettingsSection> {
  PushPermissionStatus _status = PushPermissionStatus.notDetermined;
  bool _loading = true;
  bool _serviceFailed = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _loading = true;
      _serviceFailed = false;
    });
    final read =
        widget.readPermissionStatus ??
        PushNotificationService.getPermissionStatus;
    try {
      final status = await read();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
        _serviceFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _serviceFailed = true;
      });
    }
  }

  Future<void> _enableNotifications() async {
    final request =
        widget.requestPermission ??
        PushNotificationService.requestPermissionFromUser;
    setState(() {
      _loading = true;
      _serviceFailed = false;
    });
    try {
      final status = await request();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _serviceFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusText = switch (_status) {
      PushPermissionStatus.unsupported => l10n.notificationsUnsupported,
      PushPermissionStatus.notDetermined => l10n.notificationsNotEnabled,
      PushPermissionStatus.denied => l10n.notificationsPermissionDenied,
      PushPermissionStatus.provisional =>
        l10n.notificationsPermissionProvisional,
      PushPermissionStatus.authorized => l10n.notificationsPermissionEnabled,
    };
    final canRequest =
        _status == PushPermissionStatus.notDetermined &&
        !_loading &&
        !_serviceFailed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.notificationsSettingsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(_serviceFailed ? l10n.errorLoadingData : statusText),
            if (_serviceFailed && !_loading)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _refreshStatus,
                  child: Text(l10n.actionRetry),
                ),
              ),
            if (_status == PushPermissionStatus.denied) ...[
              const SizedBox(height: 6),
              Text(l10n.notificationsDeniedHelp),
            ],
            if (canRequest) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _enableNotifications,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(l10n.notificationsEnableAction),
                ),
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
