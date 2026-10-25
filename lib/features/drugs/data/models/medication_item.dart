class MedicationItem {
  final int id;
  final String tradeName;
  final String scientificName;
  final String usage;
  final String company;
  final String agent;
  final String pharmaceuticalForm;
  final double? price;
  final String agentsPhoneNumber;
  final int? country;

  MedicationItem({
    required this.id,
    required this.tradeName,
    required this.scientificName,
    required this.usage,
    required this.company,
    required this.agent,
    required this.pharmaceuticalForm,
    required this.price,
    required this.agentsPhoneNumber,
    required this.country,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      id: _asInt(json['id']),
      tradeName: (json['tradeName'] ?? '').toString(),
      scientificName: (json['scientificName'] ?? '').toString(),
      usage: (json['usage'] ?? '').toString(),
      company: (json['company'] ?? '').toString(),
      agent: (json['agent'] ?? '').toString(),
      pharmaceuticalForm: (json['pharmaceuticalForm'] ?? '').toString(),
      price: _asDouble(json['price']),
      agentsPhoneNumber: (json['agentsPhoneNumber'] ?? '').toString(),
      country: int.tryParse(json['country']?.toString() ?? ''),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _asDouble(dynamic value) {
    final price =
        value is num
            ? value.toDouble()
            : double.tryParse(value?.toString() ?? '');
    return price?.isFinite == true ? price : null;
  }
}
