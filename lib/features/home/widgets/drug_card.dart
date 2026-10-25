import 'package:flutter/material.dart';

class DrugCard extends StatelessWidget {
  final String brandName;
  final String scientificName;
  final String company;
  final VoidCallback onTap;

  const DrugCard({
    super.key,
    required this.brandName,
    required this.scientificName,
    required this.company,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sciColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final chipColor =
        isDark ? Colors.white.withValues(alpha: .08) : primary.withValues(alpha: .10);
    final chipTextColor = isDark ? const Color(0xFFF5F7FF) : const Color(0xFF0F172A);
    final chevronColor = isDark ? const Color(0xFFF5F7FF) : const Color(0xFF0F172A);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: primary.withValues(alpha: .12),
                ),
                child: Icon(Icons.medication_outlined, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brandName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scientificName,
                      style: TextStyle(color: sciColor),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: chipColor,
                      ),
                      child: Text(
                        company,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: chipTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: chevronColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
