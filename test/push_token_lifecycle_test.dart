import 'dart:async';

import 'package:digitalpharmacy/services/notifications/push_token_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'acquisition waits for APNs readiness and succeeds on a later retry',
    () async {
      String? apns;
      var fetches = 0;
      final acquirer = PushTokenAcquirer(
        fetchApnsToken: () async => apns,
        fetchToken: () async {
          fetches++;
          return 'synthetic-fcm';
        },
      );
      expect(await acquirer.call(), isNull);
      expect(fetches, 0);
      apns = 'synthetic-apns';
      expect(await acquirer.call(), 'synthetic-fcm');
      expect(fetches, 1);
    },
  );

  test(
    'Android acquisition does not depend on an APNs or alert-permission gate',
    () async {
      final acquirer = PushTokenAcquirer(
        fetchToken: () async => 'synthetic-android',
      );
      expect(await acquirer.call(), 'synthetic-android');
    },
  );

  test(
    'refresh errors retain the current token and a later refresh recovers',
    () async {
      final refreshes = StreamController<String>();
      final published = <String>[];
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: () async => 'synthetic-original',
        tokenRefreshes: refreshes.stream,
        onTokenChanged: published.add,
      );
      await lifecycle.start();
      refreshes.addError(StateError('synthetic refresh failure'));
      await Future<void>.delayed(Duration.zero);
      expect(lifecycle.currentToken, 'synthetic-original');
      refreshes.add('synthetic-replacement');
      await Future<void>.delayed(Duration.zero);
      expect(published, ['synthetic-original', 'synthetic-replacement']);
      await lifecycle.dispose();
      await refreshes.close();
    },
  );
  test('disposed lifecycle ignores a late token lookup', () async {
    final refreshes = StreamController<String>();
    final response = Completer<String?>();
    final published = <String>[];
    final lifecycle = PushTokenLifecycle(
      fetchCurrentToken: () => response.future,
      tokenRefreshes: refreshes.stream,
      onTokenChanged: published.add,
    );
    final starting = lifecycle.start();
    await lifecycle.dispose();
    response.complete('synthetic-late-token');
    await starting;
    expect(lifecycle.currentToken, isNull);
    expect(published, isEmpty);
    await refreshes.close();
  });

  test(
    'cleared registration rejects stale success for the same token',
    () async {
      final pending = PendingPushTokenRegistration()..markPending('same-token');
      final response = Completer<bool>();
      final retry = pending.retry((_) => response.future);
      pending.clear();
      pending.markPending('same-token');
      response.complete(true);
      await retry;
      expect(pending.hasPendingRegistration, isTrue);
    },
  );
  test(
    'loads current token and forwards only changed refreshed tokens',
    () async {
      final refreshes = StreamController<String>();
      final published = <String>[];
      final lifecycle = PushTokenLifecycle(
        fetchCurrentToken: () async => ' synthetic-token-1 ',
        tokenRefreshes: refreshes.stream,
        onTokenChanged: published.add,
      );

      await lifecycle.start();
      refreshes.add('synthetic-token-1');
      refreshes.add('synthetic-token-2');
      await Future<void>.delayed(Duration.zero);

      expect(lifecycle.currentToken, 'synthetic-token-2');
      expect(published, ['synthetic-token-1', 'synthetic-token-2']);

      await lifecycle.dispose();
      await refreshes.close();
    },
  );

  test('a refreshed token wins over a late initial lookup', () async {
    final refreshes = StreamController<String>();
    final initialLookup = Completer<String?>();
    final published = <String>[];
    final lifecycle = PushTokenLifecycle(
      fetchCurrentToken: () => initialLookup.future,
      tokenRefreshes: refreshes.stream,
      onTokenChanged: published.add,
    );

    final starting = lifecycle.start();
    refreshes.add('synthetic-new-token');
    await Future<void>.delayed(Duration.zero);
    initialLookup.complete('synthetic-stale-token');
    await starting;

    expect(lifecycle.currentToken, 'synthetic-new-token');
    expect(published, ['synthetic-new-token']);

    await lifecycle.dispose();
    await refreshes.close();
  });

  test('registration failure remains pending and can be retried', () async {
    final pending = PendingPushTokenRegistration();
    pending.markPending(' synthetic-fcm-token ');
    expect(pending.hasPendingRegistration, isTrue);

    var attemptedToken = '';
    final failed = await pending.retry((token) async {
      attemptedToken = token;
      return false;
    });
    expect(failed, isFalse);
    expect(attemptedToken, 'synthetic-fcm-token');
    expect(pending.hasPendingRegistration, isTrue);

    final succeeded = await pending.retry((token) async {
      attemptedToken = token;
      return true;
    });
    expect(succeeded, isTrue);
    expect(attemptedToken, 'synthetic-fcm-token');
    expect(pending.hasPendingRegistration, isFalse);
  });

  test('a late registration cannot clear a newer refreshed token', () async {
    final pending = PendingPushTokenRegistration()..markPending('old-token');
    final response = Completer<bool>();
    final retry = pending.retry((_) => response.future);

    pending.markPending('new-token');
    response.complete(true);
    await retry;

    expect(pending.hasPendingRegistration, isTrue);
    final registered = <String>[];
    await pending.retry((token) async {
      registered.add(token);
      return true;
    });
    expect(registered, ['new-token']);
    expect(pending.hasPendingRegistration, isFalse);
  });
}
