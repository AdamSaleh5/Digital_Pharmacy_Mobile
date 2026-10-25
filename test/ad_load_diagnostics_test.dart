import 'dart:convert';

import 'package:digitalpharmacy/services/ads/ad_load_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  test('retains SDK failure domain, code and absent response evidence', () {
    final result = adLoadFailureDiagnostics(
      LoadAdError(0, 'com.google.android.gms.ads', 'Internal error.', null),
    );
    expect(result['code'], 0);
    expect(result['domain'], 'com.google.android.gms.ads');
    expect(result['message'], 'Internal error.');
    expect(result['hasResponseInfo'], false);
    expect(result['hasResponseId'], false);
    expect(result['adapters'], isEmpty);
  });

  test(
    'retains adapter errors while excluding SDK identifiers and mappings',
    () {
      final result = adLoadFailureDiagnostics(
        LoadAdError(
          0,
          'com.google.android.gms.ads',
          'Internal error.',
          ResponseInfo(
            responseId: 'private-response',
            mediationAdapterClassName: 'com.google.ads.Adapter',
            responseExtras: {'secret': 'private-extra'},
            adapterResponses: [
              AdapterResponseInfo(
                adapterClassName: 'com.google.ads.Adapter',
                latencyMillis: 42,
                description: 'private-description',
                adUnitMapping: {'key': 'private-mapping'},
                adSourceName: 'private-source-name',
                adSourceId: 'private-source-id',
                adSourceInstanceName: 'private-instance-name',
                adSourceInstanceId: 'private-instance-id',
                adError: AdError(2, 'com.google.ads', 'Network error.'),
              ),
            ],
          ),
        ),
      );
      expect(result['hasResponseId'], true);
      expect(result['adapters'], [
        {
          'class': 'com.google.ads.Adapter',
          'latencyMillis': 42,
          'error': {
            'code': 2,
            'domain': 'com.google.ads',
            'message': 'Network error.',
          },
        },
      ]);
      expect(jsonEncode(result), isNot(contains('private-')));
    },
  );

  test('sanitizes error text and rejects arbitrary domain payloads', () {
    final result = adLoadFailureDiagnostics(
      LoadAdError(
        0,
        'token=private-domain',
        'Failed https://example.com/private-path token=private-token password=private-password Bearer private-bearer person@example.com abcdef0123456789abcdef0123456789',
        null,
      ),
    );
    final encoded = jsonEncode(result);
    expect(result['domain'], '[redacted]');
    expect(encoded, isNot(contains('private-')));
    expect(encoded, isNot(contains('example.com')));
    expect(encoded, isNot(contains('abcdef0123456789')));
  });
}
