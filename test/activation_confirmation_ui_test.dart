import 'dart:async';
import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/activation/view/activation_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/services/ads/activation_entitlement_restorer.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ServerAdapter implements ActivationVerifier {
  _ServerAdapter(this.reply);
  final Future<ActivationVerification> Function() reply;
  @override
  Future<ActivationVerification> verifyDevice({
    required String activationCode,
    bool? isNewUser,
    String? deviceId,
  }) => reply();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ads = AdsEntitlementController.instance;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ads.setFree();
    ads.setPrivacyPermission(true);
  });
  tearDown(() {
    ads.setFree();
    ads.setPrivacyPermission(false);
  });
  for (final lang in ['en', 'ar']) {
    testWidgets(
      'SIMULATED approved code shows $lang success and persists confirmation',
      (tester) async {
        final session =
            AuthSession()..start(
              accessToken: 'synthetic-session',
              apiOrigin: Uri.parse('https://api.example.test'),
            );
        final prefs = await SharedPreferences.getInstance();
        final restorer = ActivationEntitlementRestorer(
          preferences: prefs,
          ads: ads,
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ActivationPage(
              apiOrigin: Uri.parse('https://api.example.test'),
              deviceId: 'synthetic-fcm-test-token',
              session: session,
              restorer: restorer,
              verifier: _ServerAdapter(
                () async => ActivationVerification.active(
                  confirmedScope: 'synthetic-binding',
                ),
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField), 'synthetic-code');
        await tester.tap(
          find.text(lang == 'en' ? 'Verify code' : 'تحقق من الكود'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            lang == 'en'
                ? 'Activation confirmed. All ads are off.'
                : 'تم تأكيد التفعيل. جميع الإعلانات متوقفة.',
          ),
          findsOneWidget,
        );
        expect(ads.canRequestAds, isFalse);
        expect(
          prefs.getString(ActivationEntitlementRestorer.historyKey),
          'synthetic-binding',
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        session.signOut();
        await tester.pumpAndSettle();
        expect(
          find.text(
            lang == 'en'
                ? 'Activation confirmed. All ads are off.'
                : 'تم تأكيد التفعيل. جميع الإعلانات متوقفة.',
          ),
          findsOneWidget,
        );
      },
    );
  }
  testWidgets('installation reset discards a late confirmation UI', (
    tester,
  ) async {
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-first',
          apiOrigin: Uri.parse('https://api.example.test'),
        );
    final restorer = ActivationEntitlementRestorer(
      preferences: await SharedPreferences.getInstance(),
      ads: ads,
    );
    final reply = Completer<ActivationVerification>();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActivationPage(
          apiOrigin: Uri.parse('https://api.example.test'),
          deviceId: 'synthetic-fcm-test-token',
          session: session,
          verifier: _ServerAdapter(() => reply.future),
          restorer: restorer,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'synthetic-code');
    await tester.tap(find.text('Verify code'));
    await tester.pump();
    await restorer.clear();
    await tester.pump();
    reply.complete(
      ActivationVerification.active(confirmedScope: 'synthetic-old-binding'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Activation confirmed. All ads are off.'), findsNothing);
    expect(find.text('Checking code…'), findsNothing);
    expect(ads.state, AdsEntitlementState.free);
  });
}
