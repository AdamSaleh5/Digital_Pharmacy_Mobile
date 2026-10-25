class ApiCountry {
  const ApiCountry({required this.id, required this.name});

  final int id;
  final String name;

  factory ApiCountry.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final nameValue = json['name'];
    final id = idValue is int ? idValue : int.tryParse('$idValue');
    if (id == null || nameValue is! String || nameValue.trim().isEmpty) {
      throw const FormatException(
        'Country response must contain an integer id and a non-empty name.',
      );
    }
    return ApiCountry(id: id, name: nameValue.trim());
  }
}
