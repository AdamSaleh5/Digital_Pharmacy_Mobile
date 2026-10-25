import 'package:digitalpharmacy/core/widgets/inline_native_ad_card.dart';
import 'package:digitalpharmacy/services/ads/ads_entitlement_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('suppressed native slots leave no residual list spacing', (
    tester,
  ) async {
    AdsEntitlementController.instance.beginRestoration();
    const listKey = Key('measured-list');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Column(
              key: listKey,
              mainAxisSize: MainAxisSize.min,
              children: interleaveNativeAds(
                List.generate(11, (_) => const SizedBox(height: 10)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.getSize(find.byKey(listKey)).height, 110);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    AdsEntitlementController.instance.setFree();
    AdsEntitlementController.instance.setPrivacyPermission(false);
  });
}
