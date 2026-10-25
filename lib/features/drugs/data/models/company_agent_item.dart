class CompanyAgentItem {
  final int id;
  final String company;
  final String agent;

  CompanyAgentItem({
    required this.id,
    required this.company,
    required this.agent,
  });

  factory CompanyAgentItem.fromJson(Map<String, dynamic> json) {
    return CompanyAgentItem(
      id: _asInt(json['id']),
      company: (json['company'] ?? '').toString(),
      agent: (json['agent'] ?? '').toString(),
    );
  }

  bool get isSelectable =>
      id > 0 &&
      company.trim().isNotEmpty &&
      !const {'0', '***', '?'}.contains(company.trim());

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
