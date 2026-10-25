import 'app_config.dart';

/// Deployment data, never inferred from enum order, a label or an old API.
/// The ordinary build uses the human-supplied 2026-10-15 mapping for this origin.
/// This provenance is not a server country-dictionary export.
class ApiCountryBindings {
  const ApiCountryBindings({
    this.origin = 'http://144.91.111.63:5002',
    this.jordanId,
    this.palestineId,
    this.evidence = '',
  }) : _configurationError = null;

  const ApiCountryBindings._invalid(this._configurationError)
    : origin = '',
      jordanId = null,
      palestineId = null,
      evidence = '';

  factory ApiCountryBindings.fromEnvironment() {
    const overridden =
        bool.hasEnvironment('DIGITAL_PHARMACY_JORDAN_COUNTRY_ID') ||
        bool.hasEnvironment('DIGITAL_PHARMACY_PALESTINE_COUNTRY_ID') ||
        bool.hasEnvironment('DIGITAL_PHARMACY_COUNTRY_BINDINGS_ORIGIN') ||
        bool.hasEnvironment('DIGITAL_PHARMACY_COUNTRY_BINDINGS_EVIDENCE');
    if (!overridden) {
      return const ApiCountryBindings(
        jordanId: 0,
        palestineId: 1,
        evidence:
            'Human instruction 2026-10-15: Jordan=0, Palestine=1; not a server dictionary export',
      );
    }
    const jordan = String.fromEnvironment('DIGITAL_PHARMACY_JORDAN_COUNTRY_ID');
    const palestine = String.fromEnvironment(
      'DIGITAL_PHARMACY_PALESTINE_COUNTRY_ID',
    );
    final jordanId = jordan.isEmpty ? null : int.tryParse(jordan);
    final palestineId = palestine.isEmpty ? null : int.tryParse(palestine);
    if ((jordan.isNotEmpty && jordanId == null) ||
        (palestine.isNotEmpty && palestineId == null)) {
      return const ApiCountryBindings._invalid(
        'Country IDs must be explicit integers.',
      );
    }
    return ApiCountryBindings(
      origin: const String.fromEnvironment(
        'DIGITAL_PHARMACY_COUNTRY_BINDINGS_ORIGIN',
        defaultValue: 'http://144.91.111.63:5002',
      ),
      jordanId: jordanId,
      palestineId: palestineId,
      evidence: const String.fromEnvironment(
        'DIGITAL_PHARMACY_COUNTRY_BINDINGS_EVIDENCE',
      ),
    );
  }

  final String origin;
  final int? jordanId;
  final int? palestineId;
  final String evidence;
  final String? _configurationError;

  int? idFor(AppCountry country, Uri requestOrigin) {
    if (_configurationError != null) throw StateError(_configurationError);
    if (jordanId == null && palestineId == null) return null;
    final bound = Uri.tryParse(origin);
    if (bound == null ||
        !bound.hasScheme ||
        !bound.hasAuthority ||
        (bound.path.isNotEmpty && bound.path != '/') ||
        bound.hasQuery ||
        bound.hasFragment ||
        bound.userInfo.isNotEmpty ||
        bound.origin != requestOrigin.origin ||
        evidence.trim().isEmpty ||
        (jordanId != null && (jordanId! < 0 || jordanId! > 0x7fffffff)) ||
        (palestineId != null &&
            (palestineId! < 0 || palestineId! > 0x7fffffff)) ||
        (jordanId != null && jordanId == palestineId)) {
      throw StateError(
        'Country bindings need distinct supplied IDs, evidence and the matching API origin.',
      );
    }
    // The supplied Jordan ID is zero. Absence is null, never a truthiness check.
    return country == AppCountry.jordan ? jordanId : palestineId;
  }
}
