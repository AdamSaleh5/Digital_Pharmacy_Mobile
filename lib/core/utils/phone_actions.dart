import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'phone_utils.dart';

String normalizePhone(String number) {
  final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
  if (cleaned.startsWith('+')) return cleaned;
  if (cleaned.startsWith('0')) {
    return cleaned.replaceFirst('0', '+962');
  }
  if (cleaned.startsWith('962')) {
    return '+$cleaned';
  }
  return cleaned;
}

Future<void> copyPhone(BuildContext context, String number) async {
  if (number.trim().isEmpty) return;
  await copyNumber(context, number);
}

Future<void> callPhone(String number) async {
  final normalized = normalizePhone(number);
  if (normalized.trim().isEmpty) return;

  final uri = Uri.parse('tel:$normalized');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
