import '../../l10n/app_localizations.dart';

/// Preserve the server number without assigning a currency from UI country.
String priceForDisplay({
  required String formattedPrice,
  required bool currencyKnown,
  required AppLocalizations l10n,
}) =>
    currencyKnown
        ? formattedPrice
        : '$formattedPrice (${l10n.priceCurrencyUnspecified})';
