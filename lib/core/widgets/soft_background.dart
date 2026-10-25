import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Provides the soft gradient background used across pages.
class SoftBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SoftBackground({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = theme.brightness == Brightness.dark
        ? AppTheme.darkBackgroundGradient
        : AppTheme.backgroundGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: theme.scaffoldBackgroundColor,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
