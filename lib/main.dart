import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import 'core/config/app_config.dart';
import 'core/providers/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'services/notifications/push_notification_service.dart';
import 'services/ads/ad_consent_service.dart';

bool get _supportsFirebasePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() => runDigitalPharmacy();

/// Restores local state and renders the app independently of push availability.
/// The optional initializer also lets startup regressions exercise a stalled or
/// unavailable native service without contacting Firebase.
Future<void> runDigitalPharmacy({
  Future<void> Function()? initializePush,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final appProvider = AppProvider();
  await appProvider.init();
  final localeProvider = LocaleProvider();
  await localeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: appProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: const DigitalPharmacyApp(),
    ),
  );
  unawaited(_startOptionalPush(initializePush ?? _initializePush));
}

Future<void> _initializePush() async {
  if (!_supportsFirebasePlatform) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await PushNotificationService.initialize();
}

Future<void> _startOptionalPush(Future<void> Function() initialize) async {
  try {
    await initialize();
  } catch (_) {
    // An optional native service must never prevent access to local data or
    // public catalogues. Avoid logging exception payloads or identifiers.
    if (kDebugMode) debugPrint('[Startup] Push service unavailable.');
  }
}

class DigitalPharmacyApp extends StatefulWidget {
  const DigitalPharmacyApp({super.key});

  @override
  State<DigitalPharmacyApp> createState() => _DigitalPharmacyAppState();
}

class _DigitalPharmacyAppState extends State<DigitalPharmacyApp>
    with WidgetsBindingObserver {
  bool _didCheckCountryPrompt = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(PushNotificationService.refreshTokenIfAvailable());
      final app = _navigatorKey.currentContext?.read<AppProvider>();
      if (app != null) unawaited(app.restoreActivation());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleCountryPrompt(BuildContext materialContext) {
    if (_didCheckCountryPrompt) return;
    _didCheckCountryPrompt = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final navContext = _navigatorKey.currentContext;
      if (navContext == null) {
        _didCheckCountryPrompt = false;
        return;
      }
      await _ensureCountrySelected(navContext);
      if (!mounted || _navigatorKey.currentState?.canPop() != false) return;
      await AdConsentService.instance.gatherConsent();
    });
  }

  Future<void> _ensureCountrySelected(BuildContext materialContext) async {
    final app = materialContext.read<AppProvider>();
    if (!app.shouldAskForCountry) return;

    final l10n = AppLocalizations.of(materialContext);
    if (l10n == null) return;
    final detected = app.detectedCountry;

    if (detected != null) {
      final detectedName =
          detected == AppCountry.jordan
              ? l10n.countryJordan
              : l10n.countryPalestine;

      final confirmed = await showDialog<bool>(
        context: materialContext,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.countryConfirmTitle),
            content: Text(l10n.countryConfirmMessage(detectedName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.commonNo),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.commonYes),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      if (confirmed == true) {
        await app.setCountry(detected);
        return;
      }
    }

    if (!materialContext.mounted) return;
    await _showCountryPicker(materialContext);
  }

  Future<void> _showCountryPicker(BuildContext materialContext) async {
    final app = materialContext.read<AppProvider>();
    final l10n = AppLocalizations.of(materialContext);
    if (l10n == null) return;
    final selected = await showDialog<AppCountry>(
      context: materialContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.countryChooseTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () => Navigator.of(dialogContext).pop(AppCountry.jordan),
                leading: const Icon(Icons.flag_circle_outlined),
                title: Text(l10n.countryJordan),
                subtitle: const Text('د.أ'),
              ),
              ListTile(
                onTap:
                    () => Navigator.of(dialogContext).pop(AppCountry.palestine),
                leading: const Icon(Icons.flag_circle_outlined),
                title: Text(l10n.countryPalestine),
                subtitle: const Text('₪'),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      await app.setCountry(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'DigitalPharmacy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: app.themeMode,
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (materialContext, child) {
        _scheduleCountryPrompt(materialContext);
        return child ?? const SizedBox.shrink();
      },
      home: const AppShell(),
    );
  }
}
