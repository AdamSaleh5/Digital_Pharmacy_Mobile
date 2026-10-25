import 'package:flutter/material.dart';

class ScientificNameTile extends StatelessWidget {
  final String name;
  final VoidCallback? onTap;

  const ScientificNameTile({
    super.key,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gradient = LinearGradient(
      colors:
          isDark
              ? const [Color(0xFF1E2B45), Color(0xFF283958)]
              : const [Color(0xFFF3F7FF), Color(0xFFE5EEFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withValues(alpha: .08)
                    : const Color(0xFFD5E1FF),
          ),
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: const Color(0xFF3A66C1).withValues(alpha: .12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            Icon(
              onTap == null ? Icons.info_outline : Icons.arrow_back_ios_new,
              size: 16,
              color: isDark ? Colors.white70 : theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
