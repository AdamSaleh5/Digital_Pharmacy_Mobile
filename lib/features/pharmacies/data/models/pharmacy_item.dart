class PharmacyItem {
  final int id;
  final String name;
  final String address;
  final String managerName;
  final String phoneNumber;
  final int? country;

  PharmacyItem({
    required this.id,
    required this.name,
    required this.address,
    required this.managerName,
    required this.phoneNumber,
    required this.country,
  });

  factory PharmacyItem.fromJson(Map<String, dynamic> json) {
    return PharmacyItem(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      managerName: (json['managerName'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      country: int.tryParse(json['country']?.toString() ?? ''),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
