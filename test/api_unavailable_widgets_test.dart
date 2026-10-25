import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/api_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/drugs/widgets/dosage_forms_sheet.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:digitalpharmacy/l10n/app_localizations_en.dart';
import 'package:digitalpharmacy/data/models/drug.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('contract-limited dosage form shows explanation without retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DosageFormsSheet(
            drugName: 'Example',
            loadForms:
                (_) async =>
                    throw const ApiContractUnavailable(
                      'missing response schema',
                    ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsEn().apiContractUnavailable),
      findsOneWidget,
    );
    expect(find.text(AppLocalizationsEn().actionRetry), findsNothing);
  });

  testWidgets('offline dosage form state shows retry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DosageFormsSheet(
            drugName: 'Example',
            loadForms:
                (_) async =>
                    throw DioException.connectionError(
                      requestOptions: RequestOptions(path: '/forms'),
                      reason: 'offline in test',
                    ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppLocalizationsEn().errorLoadingData), findsOneWidget);
    expect(find.text(AppLocalizationsEn().actionRetry), findsOneWidget);
  });

  testWidgets(
    'service access failure shows a retry without any sign-in prompt',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DosageFormsSheet(
              drugName: 'Example',
              loadForms:
                  (_) async =>
                      throw DioException(
                        requestOptions: RequestOptions(path: '/forms'),
                        response: Response(
                          requestOptions: RequestOptions(path: '/forms'),
                          statusCode: 401,
                        ),
                      ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppLocalizationsEn().apiAuthenticationRequired),
        findsOneWidget,
      );
      expect(find.text(AppLocalizationsEn().actionRetry), findsOneWidget);
      expect(find.textContaining('Sign in'), findsNothing);
    },
  );

  testWidgets('empty dosage form response shows the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DosageFormsSheet(
            drugName: 'Example',
            loadForms: (_) async => const [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppLocalizationsEn().noFormsAvailable), findsOneWidget);
  });

  testWidgets('admin logout does not block public dosage data reload', (
    tester,
  ) async {
    final session =
        AuthSession()..start(
          accessToken: 'synthetic-token',
          apiOrigin: Uri.parse('https://api.example.test'),
        );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DosageFormsSheet(
            drugName: 'Synthetic medicine',
            session: session,
            loadForms:
                (_) async => [
                  DosageFormPrice(formName: 'synthetic tablet', priceJod: 1),
                ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('synthetic tablet'), findsOneWidget);

    session.signOut();
    await tester.pumpAndSettle();
    expect(find.text('synthetic tablet'), findsOneWidget);
    expect(
      find.text(AppLocalizationsEn().apiAuthenticationRequired),
      findsNothing,
    );
    expect(find.text(AppLocalizationsEn().actionRetry), findsNothing);
  });
}
