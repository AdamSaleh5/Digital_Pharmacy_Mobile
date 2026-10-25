import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/api_errors.dart';
import 'package:digitalpharmacy/core/network/api_transport.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/core/providers/locale_provider.dart';
import 'package:digitalpharmacy/features/settings/settings_page.dart';
import 'package:digitalpharmacy/features/settings/auth_settings_section.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'default public transport never inherits a shared admin session',
    () async {
      final origin = Uri.parse('http://144.91.111.63:5002');
      AuthSession.shared.start(
        accessToken: 'synthetic-admin-only',
        apiOrigin: Uri.parse('https://api.example.test'),
      );
      addTearDown(AuthSession.shared.signOut);
      final dio = Dio(BaseOptions(baseUrl: origin.toString()));
      final transport = ApiTransport(dio: dio);
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(requestOptions: request, statusCode: 200, data: []),
            );
          },
        ),
      );
      await transport.get<dynamic>('/api/GetCompanySeletc');
      expect(requests.single.headers['Authorization'], isNull);
      expect(AuthSession.shared.isSignedIn, isTrue);
      dio.close();
    },
  );
  for (final status in [401, 403]) {
    test('public $status is a service access error with manual retry', () {
      final request = RequestOptions(path: '/api/GetCountries');
      final error = DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: status),
      );
      final message = apiFailureMessage(error, AppLocalizationsEn());
      expect(message, contains('service'));
      expect(message.toLowerCase(), isNot(contains('sign in')));
      expect(isApiFailureRetryable(error), isTrue);
    });
  }
  testWidgets('anonymous Settings exposes preferences without admin login', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppProvider();
    final locale = LocaleProvider();
    await app.init();
    await locale.init();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppProvider>.value(value: app),
          ChangeNotifierProvider<LocaleProvider>.value(value: locale),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AuthSettingsSection), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Sign in'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
    locale.dispose();
  });
}
