import 'package:flutter/foundation.dart';

/// Server-confirmed state used by ad surfaces.
///
/// Until the backend returns an explicit active entitlement, use [unknown].
/// Pending restoration suppresses ads; only [inactive] allows requests.
enum EntitlementStatus { unknown, inactive, active }

@immutable
class AdEntitlementSnapshot {
  const AdEntitlementSnapshot(this.status);

  const AdEntitlementSnapshot.unknown() : status = EntitlementStatus.unknown;

  final EntitlementStatus status;

  bool get isAdFree => status == EntitlementStatus.active;
}

/// Read-only contract for ad widgets/services; only a server-backed source
/// should publish [EntitlementStatus.active].
abstract interface class AdEntitlementReader {
  ValueListenable<AdEntitlementSnapshot> get adEntitlement;
}
