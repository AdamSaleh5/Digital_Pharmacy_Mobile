import 'package:digitalpharmacy/core/network/activation_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/activation/view/activation_page.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeActivationVerifier implements ActivationVerifier {
  _FakeActivationVerifier();
  String? submittedCode;
  bool shouldThrow = false;

  @override
  Future<ActivationVerification> verifyDevice({
    required String activationCode,
    bool? isNewUser,
    String? deviceId,
  }) async {
    submittedCode = activationCode;
    if (shouldThrow) throw StateError('synthetic verification error');
    return ActivationVerification.unconfirmed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AdsEntitlementController.instance.setFree());

  testWidgets('HTTP activation is disabled before code or token acquisition', (
    tester,
  ) async {
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-https-session',
          apiOrigin: Uri.parse('https://api.example.test'),
        );
    final verifier = _FakeActivationVerifier();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActivationPage(
          deviceId: 'synthetic-fcm-test-token',
          verifier: verifier,
          session: session,
          apiOrigin: Uri.parse('http://144.91.111.63:5002'),
        ),
      ),
    );

    expect(
      find.text(
        'Activation is unavailable until a secure connection is configured. Your saved ad setting is unchanged.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(verifier.submittedCode, isNull);
  });

  testWidgets(
    'anonymous activation is enabled and never infers confirmation on 200',
    (tester) async {
      final session = AuthSession();
      final verifier = _FakeActivationVerifier();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ActivationPage(
            deviceId: 'synthetic-fcm-test-token',
            verifier: verifier,
            session: session,
            apiOrigin: Uri.parse('https://api.example.test'),
          ),
        ),
      );

      expect(find.textContaining('Sign in'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.enterText(find.byType(TextField), ' synthetic-code ');
      await tester.tap(find.text('Verify code'));
      await tester.pumpAndSettle();

      expect(verifier.submittedCode, 'synthetic-code');
      expect(
        find.text(
          'The server did not confirm the code\'s status. Your current ad setting has not changed.',
        ),
        findsOneWidget,
      );
      expect(find.text('The app could not verify this code.'), findsNothing);
      expect(AdsEntitlementController.instance.adsAllowed, isTrue);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        (tester.widget(find.byType(TextField)) as TextField).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('shows generic failure without labeling code invalid', (
    tester,
  ) async {
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-activation-session',
          apiOrigin: Uri.parse('https://api.example.test'),
        );
    final verifier = _FakeActivationVerifier()..shouldThrow = true;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActivationPage(
          deviceId: 'synthetic-fcm-test-token',
          verifier: verifier,
          session: session,
          apiOrigin: Uri.parse('https://api.example.test'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'synthetic-code');
    await tester.tap(find.text('Verify code'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to verify the code. Please try again later.'),
      findsOneWidget,
    );
    expect(find.text('Invalid activation code'), findsNothing);
    expect(AdsEntitlementController.instance.adsAllowed, isTrue);
  });

  testWidgets('empty code is rejected locally without calling the API', (
    tester,
  ) async {
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-activation-session',
          apiOrigin: Uri.parse('https://api.example.test'),
        );
    final verifier = _FakeActivationVerifier();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActivationPage(
          deviceId: 'synthetic-fcm-test-token',
          verifier: verifier,
          session: session,
          apiOrigin: Uri.parse('https://api.example.test'),
        ),
      ),
    );

    await tester.tap(find.text('تحقق من الكود'));
    await tester.pump();

    expect(verifier.submittedCode, isNull);
    expect(find.text('أدخل كود التفعيل.'), findsOneWidget);
  });
}
