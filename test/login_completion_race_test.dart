import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:digitalpharmacy/core/network/api_auth_service.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/settings/auth_settings_section.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _origin = 'https://api.example.test';

// Socketless adapter; all secrets below are synthetic and never transmitted.
class _Adapter implements HttpClientAdapter {
  final seen = StreamController<int>.broadcast();
  final responses = <Completer<ResponseBody>>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final response = Completer<ResponseBody>();
    responses.add(response);
    seen.add(responses.length);
    return response.future;
  }

  void respond(int index, {bool valid = true}) {
    responses[index].complete(
      ResponseBody.fromString(
        valid ? '{"accessToken":"synthetic-response-$index"}' : '{}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) {}
}

class _PendingAuth extends ApiAuthService {
  _PendingAuth(AuthSession session)
    : super(baseUrl: _origin, verifiedOrigin: _origin, session: session);
  final completion = Completer<void>();
  bool submitted = false;

  @override
  Future<void> login({required String email, required String password}) async {
    submitted = true;
    await completion.future;
    session.start(
      accessToken: 'synthetic-ui-session',
      apiOrigin: Uri.parse(_origin),
    );
  }
}

void main() {
  for (final scenario in [
    'logout-anonymous',
    'logout-signed-in',
    'replacement',
    'replacement-malformed',
    'newer-login',
  ]) {
    test('late login completion preserves $scenario intent', () async {
      final session = AuthSession();
      addTearDown(session.dispose);
      final adapter = _Adapter();
      addTearDown(adapter.seen.close);
      final dio = Dio()..httpClientAdapter = adapter;
      addTearDown(dio.close);
      final service = ApiAuthService(
        baseUrl: _origin,
        verifiedOrigin: _origin,
        session: session,
        dio: dio,
      );
      if (scenario == 'logout-signed-in') {
        session.start(
          accessToken: 'synthetic-original',
          apiOrigin: Uri.parse(_origin),
        );
      }
      final firstSeen = adapter.seen.stream.first;
      final oldLogin = service.login(
        email: 'synthetic@example.test',
        password: 'synthetic-not-transmitted',
      );
      await firstSeen;
      final oldOutcome = expectLater(
        oldLogin,
        throwsA(isA<ApiAuthException>()),
      );
      if (scenario.startsWith('logout')) {
        service.logout();
      } else if (scenario.startsWith('replacement')) {
        session.start(
          accessToken: 'synthetic-replacement',
          apiOrigin: Uri.parse(_origin),
        );
      } else {
        final nextSeen = adapter.seen.stream.first;
        final nextLogin = service.login(
          email: 'synthetic-next@example.test',
          password: 'synthetic-not-transmitted',
        );
        await nextSeen;
        adapter.respond(1);
        await nextLogin;
      }
      final revision = session.revision;
      final authorization = session.authorizationFor(
        requestUri: Uri.parse('$_origin/api/GetCountries'),
        configuredApiOrigin: Uri.parse(_origin),
      );
      adapter.respond(0, valid: scenario != 'replacement-malformed');
      await oldOutcome;
      expect(session.revision, revision);
      expect(
        session.authorizationFor(
          requestUri: Uri.parse('$_origin/api/GetCountries'),
          configuredApiOrigin: Uri.parse(_origin),
        ),
        authorization,
      );
      expect(session.isSignedIn, !scenario.startsWith('logout'));
    });
  }

  testWidgets(
    'submitted password clears immediately and completion after leaving is safe',
    (tester) async {
      final session = AuthSession();
      addTearDown(session.dispose);
      final service = _PendingAuth(session);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AuthSettingsSection(authService: service)),
        ),
      );
      await tester.enterText(
        find.byType(TextField).at(0),
        'synthetic@example.test',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'synthetic-not-transmitted',
      );
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        isEmpty,
      );
      expect(service.submitted, isTrue);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      service.completion.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(session.isSignedIn, isTrue);
    },
  );
}
