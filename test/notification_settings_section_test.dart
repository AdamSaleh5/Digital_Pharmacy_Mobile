import 'package:digitalpharmacy/features/settings/notification_settings_section.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/services/notifications/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unavailable service can retry without reporting a denial', (
    tester,
  ) async {
    var available = false;
    var granted = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotificationSettingsSection(
            readPermissionStatus: () async {
              if (!available) throw StateError('synthetic startup unavailable');
              return PushPermissionStatus.notDetermined;
            },
            requestPermission: () async {
              if (!granted) throw StateError('synthetic native failure');
              return PushPermissionStatus.authorized;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Notification permission is denied.'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    available = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notification permission is denied.'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    granted = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications are enabled.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requests notification permission only after user taps enable', (
    tester,
  ) async {
    var requestCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: NotificationSettingsSection(
            readPermissionStatus:
                () async => PushPermissionStatus.notDetermined,
            requestPermission: () async {
              requestCount++;
              return PushPermissionStatus.denied;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestCount, 0);
    expect(find.text('Enable notifications'), findsOneWidget);

    await tester.tap(find.text('Enable notifications'));
    await tester.pumpAndSettle();

    expect(requestCount, 1);
    expect(find.text('Notification permission is denied.'), findsOneWidget);
    expect(
      find.text(
        'To enable later, allow notifications for this app in your device settings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Enable notifications'), findsNothing);
  });
}
