class MedicationSuggestion {
  final String tradeName;
  final String scientificName;
  final int? id;

  /// Label returned by GetMedicationSelect for the requested SearchType.
  /// It must not be reinterpreted as both trade and scientific names.
  final String value;

  MedicationSuggestion({
    required this.tradeName,
    required this.scientificName,
    this.id,
    this.value = '',
  });

  factory MedicationSuggestion.fromJson(Map<String, dynamic> json) {
    if (json['value'] is! String &&
        !(json.containsKey('tradeName') &&
            json.containsKey('scientificName'))) {
      throw const FormatException('Medication selection needs a value label.');
    }
    return MedicationSuggestion(
      value: json['value'] is String ? json['value'] as String : '',
      tradeName: (json['tradeName'] ?? '').toString(),
      scientificName: (json['scientificName'] ?? '').toString(),
      id: _positiveId(json['id']),
    );
  }

  String label({required bool scientific}) =>
      value.trim().isNotEmpty
          ? value
          : scientific
          ? scientificName
          : tradeName;

  static int? _positiveId(dynamic value) {
    final id = value is int ? value : int.tryParse(value?.toString() ?? '');
    return id != null && id > 0 ? id : null;
  }
}
