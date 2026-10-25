import '../entitlements/ad_entitlement.dart';

/// Client decisions, deliberately independent of undocumented server JSON keys.
enum ActivationDecision { confirmed, rejected, unconfirmed }

class ActivationVerification {
  const ActivationVerification._(this.decision, this.confirmedScope);
  static const unconfirmed = ActivationVerification._(
    ActivationDecision.unconfirmed,
    null,
  );
  static const rejected = ActivationVerification._(
    ActivationDecision.rejected,
    null,
  );

  factory ActivationVerification.active({required String confirmedScope}) {
    final scope = confirmedScope.trim();
    if (scope.isEmpty) throw ArgumentError('A confirmed binding is required.');
    return ActivationVerification._(ActivationDecision.confirmed, scope);
  }

  final ActivationDecision decision;
  final String? confirmedScope;
  bool get isConfirmedActive => decision == ActivationDecision.confirmed;
  bool get isRejected => decision == ActivationDecision.rejected;
}

/// Exposes no request headers and does not retain the submitted code.
/// Response bodies may contain sensitive backend data and must never be logged.
class ActivationApiReply {
  const ActivationApiReply({
    required this.statusCode,
    required this.body,
    this.contentType,
  });
  final int? statusCode;
  final Object? body;
  final String? contentType;
}

typedef ActivationStatusLookup =
    Future<EntitlementStatus> Function(String scope);

/// Boundary for the anonymous installation activation request.
abstract class ActivationApiAdapter {
  const ActivationApiAdapter();
  String get verificationPath;
  Set<int> get handledStatusCodes => const {200};
  ActivationVerification decodeVerification(ActivationApiReply reply);

  Map<String, dynamic> verificationBody({
    required String activationCode,
    bool? isNewUser,
    String? deviceId,
  }) => {
    'activationCode': activationCode,
    if (isNewUser != null) 'isNewUser': isNewUser,
    if (deviceId != null) 'deviceId': deviceId,
  };

  /// No status endpoint, expiration or scope-transfer policy is invented.
  /// A future documented installation-bound lookup may supply this existing hook.
  ActivationStatusLookup? get statusLookup => null;
}

/// A negative probe returned {status: 200, data: false} despite HTTP 200.
/// Swagger supplies no positive response schema. Fresh confirmation must wait
/// for an authoritative contract and approved HTTPS lifecycle evidence.
class SwaggerActivationApiAdapter extends ActivationApiAdapter {
  const SwaggerActivationApiAdapter();
  @override
  String get verificationPath => '/api/users/verify-device';
  @override
  ActivationVerification decodeVerification(ActivationApiReply reply) {
    final body = reply.body;
    if (reply.statusCode != 200 || body is! Map || body['status'] != 200) {
      return ActivationVerification.unconfirmed;
    }
    if (body['data'] == false) return ActivationVerification.rejected;
    return ActivationVerification.unconfirmed;
  }
}
