import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

String _normalizeNumber(String number) {
  return number.replaceAll(RegExp(r'[^0-9+]'), '');
}

Future<void> callNumber(String number) async {
  final normalized = _normalizeNumber(number);
  if (normalized.isEmpty) return;
  final uri = Uri(scheme: 'tel', path: normalized);
  final launched = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (!launched) {
    debugPrint('Could not launch $uri');
  }
}

Future<void> copyNumber(BuildContext context, String number) async {
  final messenger = ScaffoldMessenger.of(context);
  await Clipboard.setData(ClipboardData(text: number));
  messenger.showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context)?.commonCopySuccess ?? 'Number copied')),
  );
}
