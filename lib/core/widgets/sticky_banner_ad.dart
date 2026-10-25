import 'package:flutter/material.dart';

import 'ad_banner_placement.dart';

class StickyBannerAd extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const StickyBannerAd({
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  @override
  Widget build(BuildContext context) => AdBannerPlacement(padding: padding);
}
