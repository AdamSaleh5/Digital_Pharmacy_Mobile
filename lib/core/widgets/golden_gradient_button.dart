import 'package:flutter/material.dart';

import 'pressable_scale.dart';

class GoldenGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const GoldenGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.layers_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      scale: 0.96,
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD27D), Color(0xFFFFB703)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCE8A00).withValues(alpha: .25),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2D1900)),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2D1900),
                    fontWeight: FontWeight.w700,
                  ) ??
                  const TextStyle(
                    color: Color(0xFF2D1900),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlternativesGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const AlternativesGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.compare_arrows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      scale: 0.96,
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF5B6CFF), Color(0xFF8B46FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5230C6).withOpacity(.25),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ) ??
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
