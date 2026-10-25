import 'package:google_mobile_ads/google_mobile_ads.dart';

// Deliberately omit response IDs, adapter mappings/credentials, descriptions,
// source IDs and extras. Never log an SDK object's unrestricted toString().
Map<String, Object?> adLoadFailureDiagnostics(LoadAdError error) {
  final response = error.responseInfo;
  return {
    ..._errorFields(error),
    'hasResponseInfo': response != null,
    'hasResponseId': response?.responseId?.isNotEmpty ?? false,
    'mediationAdapter': _className(response?.mediationAdapterClassName),
    'adapters': [
      for (final adapter
          in response?.adapterResponses ?? <AdapterResponseInfo>[])
        {
          'class': _className(adapter.adapterClassName),
          'latencyMillis': adapter.latencyMillis,
          'error':
              adapter.adError == null ? null : _errorFields(adapter.adError!),
        },
    ],
  };
}

Map<String, Object?> _errorFields(AdError error) => {
  'code': error.code,
  'domain': _className(error.domain),
  'message': _message(error.message),
};

String? _className(String? value) {
  if (value == null) return null;
  return value.length <= 180 && RegExp(r'^[A-Za-z0-9_.$]+$').hasMatch(value)
      ? value
      : '[redacted]';
}

String _message(String value) {
  final sanitized = value
      .replaceAll(RegExp(r'https?://\S+', caseSensitive: false), '[url]')
      .replaceAll(
        RegExp(r'\bBearer\s+\S+', caseSensitive: false),
        '[credential]',
      )
      .replaceAll(
        RegExp(
          r'\b(token|password|secret|credential)\s*[:=]\s*\S+',
          caseSensitive: false,
        ),
        '[credential]',
      )
      .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+'), '[address]')
      .replaceAll(RegExp(r'[A-Za-z0-9_:/=-]{24,}'), '[identifier]');
  return sanitized.length > 500 ? '${sanitized.substring(0, 500)}…' : sanitized;
}
