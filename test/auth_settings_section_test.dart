import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/api_auth_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/settings/auth_settings_section.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/l10n/app_localizations_ar.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSection(WidgetTester tester, Locale locale) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
    final session = AuthSession();
    final service = ApiAuthService(
      baseUrl: 'http://144.91.111.63:5002',
      session: session,
      dio: dio,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AuthSettingsSection(authService: service, session: session),
        ),
      ),
    );
  }

  testWidgets('HTTP sign-in requires HTTPS in English', (tester) async {
    await pumpSection(tester, const Locale('en'));

    expect(
      find.text(AppLocalizationsEn().authHttpsSetupNeeded),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text(AppLocalizationsEn().authSignInAction), findsNothing);
  });

  testWidgets('HTTP setup requirement is localized in Arabic', (tester) async {
    await pumpSection(tester, const Locale('ar'));

    expect(
      find.text(AppLocalizationsAr().authHttpsSetupNeeded),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('unsupported HTTP host keeps credential submission disabled', (
    tester,
  ) async {
    final service = ApiAuthService(
      baseUrl: 'http://example.test:5002',
      session: AuthSession(),
      dio: Dio(BaseOptions(baseUrl: 'http://example.test:5002')),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AuthSettingsSection(authService: service)),
      ),
    );

    expect(
      find.text(AppLocalizationsEn().authHttpsSetupNeeded),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets(
    'verified HTTPS sign-in submits only after the user presses the button',
    (tester) async {
      final session = AuthSession();
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'accessToken': 'synthetic-http-token'},
              ),
            );
          },
        ),
      );
      final service = ApiAuthService(
        baseUrl: 'https://api.example.test',
        verifiedOrigin: 'https://api.example.test',
        session: session,
        dio: dio,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AuthSettingsSection(authService: service, session: session),
          ),
        ),
      );
      expect(requests, isEmpty);
      await tester.enterText(
        find.byType(TextField).at(0),
        'synthetic@example.test',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'synthetic-password',
      );
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(requests, hasLength(1));
      expect(requests.single.uri.origin, 'https://api.example.test');
      expect(session.isSignedIn, isTrue);
    },
  );

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('login error wraps on a narrow ${locale.languageCode} screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = AuthSession();
      var requestCount = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestCount++;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 401,
                data: {'detail': 'synthetic unauthorized'},
              ),
            );
          },
        ),
      );
      final service = ApiAuthService(
        baseUrl: 'https://api.example.test',
        verifiedOrigin: 'https://api.example.test',
        session: session,
        dio: dio,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AuthSettingsSection(
                authService: service,
                session: session,
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField).at(0),
        'synthetic@example.test',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'synthetic-password',
      );
      await tester.pump();
      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.map((field) => field.controller!.text).toList(), [
        'synthetic@example.test',
        'synthetic-password',
      ]);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      final signInLabel =
          locale.languageCode == 'ar' ? 'تسجيل الدخول' : 'Sign in';
      await tester.ensureVisible(find.text(signInLabel));
      await tester.tap(find.text(signInLabel));
      await tester.pumpAndSettle();
      expect(requestCount, 1);

      final expectedMessage =
          locale.languageCode == 'ar'
              ? AppLocalizationsAr().authLoginFailed
              : AppLocalizationsEn().authLoginFailed;
      expect(find.text(expectedMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
