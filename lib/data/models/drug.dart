import '../../core/config/app_config.dart';

class Drug {
  final String id;
  final String brandName;
  final String scientificName;
  final String company;
  final String agentName;
  final String agentNumber;
  final List<DosageFormPrice> dosageForms;
  final String strength;
  final String usage;
  final double? priceJod;
  final bool priceCurrencyKnown;
  final String alternatives;
  final String country;

  const Drug({
    required this.id,
    required this.brandName,
    required this.scientificName,
    required this.company,
    required this.agentName,
    required this.agentNumber,
    required this.dosageForms,
    required this.strength,
    this.usage = '',
    required this.priceJod,
    this.priceCurrencyKnown = true,
    required this.alternatives,
    required this.country,
  });

  String get formattedPriceJod =>
      priceJod == null
          ? '—'
          : priceCurrencyKnown
          ? formatPriceByCountry(priceJod!)
          : priceJod!.toStringAsFixed(2);

  String get dosageFormsLabel => dosageForms.map((e) => e.formName).join("، ");
}

class DosageFormPrice {
  final String formName;
  final double? priceJod;
  final bool priceCurrencyKnown;

  const DosageFormPrice({
    required this.formName,
    required this.priceJod,
    this.priceCurrencyKnown = true,
  });

  String get formattedPrice =>
      priceJod == null
          ? '—'
          : priceCurrencyKnown
          ? formatPriceByCountry(priceJod!)
          : priceJod!.toStringAsFixed(2);
}
