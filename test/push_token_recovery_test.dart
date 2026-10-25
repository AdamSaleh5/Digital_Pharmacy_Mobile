import 'dart:async';
import 'package:digitalpharmacy/services/notifications/push_token_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'foreground null/offline acquisition retries within a bounded budget',
    (tester) async {
      final stream = StreamController<String>.broadcast(sync: true);
      var calls = 0;
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: () async {
          calls++;
          return null;
        },
        tokenRefreshes: stream.stream,
        onTokenChanged: (_) {},
      );
      addTearDown(() async {
        unawaited(lifecycle.dispose());
        unawaited(stream.close());
      });
      unawaited(lifecycle.start());
      await tester.pump();
      expect(calls, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(calls, 2);
      await tester.pump(const Duration(seconds: 10));
      expect(calls, 3);
      await tester.pump(const Duration(seconds: 30));
      expect(calls, 4);
      await tester.pump(const Duration(hours: 1));
      expect(calls, 4, reason: 'No unbounded retry loop');
      stream.add('synthetic-after-budget');
      await tester.pump();
      expect(lifecycle.currentToken, 'synthetic-after-budget');
      expect(calls, 4);
    },
  );
  testWidgets(
    'hung acquisition times out and a retry wins over its late result',
    (tester) async {
      final stream = StreamController<String>.broadcast(sync: true);
      final hung = Completer<String?>();
      final values = <String>[];
      var calls = 0;
      var completed = false;
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: () {
          calls++;
          return calls == 1 ? hung.future : Future.value('synthetic-recovered');
        },
        tokenRefreshes: stream.stream,
        onTokenChanged: values.add,
      );
      addTearDown(() async {
        unawaited(lifecycle.dispose());
        if (!hung.isCompleted) hung.complete(null);
        unawaited(stream.close());
      });
      unawaited(lifecycle.start().then((_) => completed = true));
      await tester.pump(const Duration(seconds: 10));
      expect(completed, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(lifecycle.currentToken, 'synthetic-recovered');
      hung.complete('synthetic-obsolete');
      await tester.pump();
      expect(values, ['synthetic-recovered']);
    },
  );
  testWidgets(
    'APNs readiness recovers without a notification permission prompt or app restart',
    (tester) async {
      final stream = StreamController<String>.broadcast(sync: true);
      String? apns;
      var fcmCalls = 0;
      final values = <String>[];
      final acquirer = PushTokenAcquirer(
        fetchApnsToken: () async => apns,
        fetchToken: () async {
          fcmCalls++;
          return 'synthetic-apple-fcm';
        },
      );
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: acquirer.call,
        tokenRefreshes: stream.stream,
        onTokenChanged: values.add,
      );
      addTearDown(() async {
        unawaited(lifecycle.dispose());
        unawaited(stream.close());
      });
      unawaited(lifecycle.start());
      await tester.pump();
      expect(fcmCalls, 0);
      apns = 'synthetic-ready-apns';
      await tester.pump(const Duration(seconds: 2));
      expect(values, ['synthetic-apple-fcm']);
      expect(fcmCalls, 1);
    },
  );
  testWidgets(
    'refresh cancels scheduled recovery and dispose cancels future work',
    (tester) async {
      final stream = StreamController<String>.broadcast(sync: true);
      var calls = 0;
      final values = <String>[];
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: () async {
          calls++;
          throw StateError('synthetic offline');
        },
        tokenRefreshes: stream.stream,
        onTokenChanged: values.add,
      );
      unawaited(lifecycle.start());
      await tester.pump();
      stream.add('synthetic-refreshed');
      await tester.pump();
      await tester.pump(const Duration(hours: 1));
      expect(calls, 1);
      expect(values, ['synthetic-refreshed']);
      unawaited(lifecycle.start());
      await tester.pump();
      expect(calls, 2);
      expect(lifecycle.currentToken, 'synthetic-refreshed');
      unawaited(lifecycle.dispose());
      await tester.pump(const Duration(hours: 1));
      expect(calls, 2);
      expect(lifecycle.currentToken, isNull);
      unawaited(stream.close());
    },
  );
  testWidgets(
    'concurrent lookups coalesce and blank refresh does not discard a valid lookup',
    (tester) async {
      final stream = StreamController<String>.broadcast(sync: true);
      final response = Completer<String?>();
      var calls = 0;
      final values = <String>[];
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: () {
          calls++;
          return response.future;
        },
        tokenRefreshes: stream.stream,
        onTokenChanged: values.add,
      );
      final one = lifecycle.start();
      final two = lifecycle.start();
      stream.add(' ');
      await tester.pump();
      response.complete('synthetic-valid');
      unawaited(Future.wait([one, two]));
      await tester.pump();
      try {
        expect(calls, 1);
        expect(values, ['synthetic-valid']);
      } finally {
        unawaited(lifecycle.dispose());
        unawaited(stream.close());
      }
    },
  );
  testWidgets(
    'a stream error keeps the last token while bounded acquisition recovers',
    (tester) async {
      final stream = StreamController<String>.broadcast(sync: true);
      var calls = 0;
      final values = <String>[];
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: () async {
          calls++;
          if (calls == 2) throw StateError('synthetic offline');
          return calls == 1 ? 'synthetic-original' : 'synthetic-recovered';
        },
        tokenRefreshes: stream.stream,
        onTokenChanged: values.add,
      );
      unawaited(lifecycle.start());
      await tester.pump();
      stream.addError(StateError('synthetic refresh transport error'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(lifecycle.currentToken, 'synthetic-original');
      await tester.pump(const Duration(seconds: 10));
      expect(values, ['synthetic-original', 'synthetic-recovered']);
      unawaited(lifecycle.dispose());
      unawaited(stream.close());
      await tester.pump();
    },
  );
  testWidgets(
    'dispose releases a hung lookup and prevents late token callbacks',
    (tester) async {
      final stream = StreamController<String>.broadcast(sync: true);
      final response = Completer<String?>();
      var finished = false;
      final values = <String>[];
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: () => response.future,
        tokenRefreshes: stream.stream,
        onTokenChanged: values.add,
      );
      unawaited(lifecycle.start().then((_) => finished = true));
      await tester.pump();
      unawaited(lifecycle.dispose());
      await tester.pump();
      expect(finished, isTrue);
      response.complete('synthetic-late');
      await tester.pump(const Duration(hours: 1));
      expect(values, isEmpty);
      expect(lifecycle.currentToken, isNull);
      unawaited(stream.close());
      await tester.pump();
    },
  );
}
