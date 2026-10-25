import 'package:flutter/material.dart';

class SearchModeChip extends StatelessWidget {
  final bool selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool darkStyle;

  const SearchModeChip({
    super.key,
    required this.selected,
    required this.title,
    required this.icon,
    required this.onTap,
    this.darkStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final background = darkStyle
        ? (selected ? Colors.white : Colors.white.withOpacity(.2))
        : (selected ? primaryColor : Colors.white);

    final textColor = darkStyle
        ? (selected ? theme.colorScheme.primary : Colors.white)
        : (selected ? Colors.white : const Color(0xFF111827));

    final iconColor = darkStyle
        ? (selected ? theme.colorScheme.primary : Colors.white70)
        : (selected ? Colors.white : const Color(0xFF111827));

    final borderColor = darkStyle
        ? Colors.transparent
        : (selected ? Colors.transparent : const Color(0xFFE5E7EB));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: selected && !darkStyle
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(.25),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
