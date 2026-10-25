import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class DPQueryBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilterTap;
  final ValueChanged<String> onSubmit;
  final Color? filledColor;
  final String? hintText;

  const DPQueryBar({
    super.key,
    required this.controller,
    required this.onFilterTap,
    required this.onSubmit,
    this.filledColor,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmit,
            decoration: InputDecoration(
              hintText: hintText ?? AppLocalizations.of(context)!.queryBarHint,
              prefixIcon: const Icon(Icons.search),
              fillColor: filledColor ?? Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC857), Color(0xFFFFA45B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA45B).withOpacity(.35),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
          ),
        )
      ],
    );
  }
}
