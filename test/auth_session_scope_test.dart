import 'package:digitalpharmacy/core/cache/memory_cache.dart';
import 'package:digitalpharmacy/core/network/auth_session.dart';
import 'package:digitalpharmacy/features/drugs/data/repository/medication_repository.dart';
import 'package:digitalpharmacy/providers/app_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackingMedicationRepository extends MedicationRepository {
  int clearCount = 0;

  @override
  void clearSessionCaches() {
    clearCount++;
    super.clearSessionCaches();
  }
}

void main() {
  test('HTTP origin cannot hold a bearer session', () {
    final session = AuthSession();
    expect(
      () => session.start(
        accessToken: 'synthetic-token',
        apiOrigin: Uri.parse('http://144.91.111.63:5002'),
      ),
      throwsArgumentError,
    );
    expect(session.isSignedIn, isFalse);
  });

  test('session changes clear API caches and notify once per transition', () {
    final session = AuthSession();
    final repository = _TrackingMedicationRepository();
    final app = AppProvider(
      medicationRepository: repository,
      authSession: session,
    );
    var notifications = 0;
    app.addListener(() => notifications++);
    MemoryCache.instance.set('session-scoped-test', 'synthetic cache');

    session.start(
      accessToken: 'synthetic-account-one',
      apiOrigin: Uri.parse('https://api.example.test'),
    );
    expect(repository.clearCount, 1);
    expect(MemoryCache.instance.get<String>('session-scoped-test'), isNull);
    expect(app.dataScopeRevision, 1);

    session.start(
      accessToken: 'synthetic-account-two',
      apiOrigin: Uri.parse('https://api.example.test'),
    );
    expect(repository.clearCount, 2);
    expect(app.authSessionRevision, 2);

    session.signOut();
    expect(repository.clearCount, 3);
    expect(app.dataScopeRevision, 3);
    final revisionAfterSignOut = app.authSessionRevision;
    session.signOut();
    expect(app.authSessionRevision, revisionAfterSignOut);
    expect(notifications, 3);

    app.dispose();
    MemoryCache.instance.clear();
  });
}
