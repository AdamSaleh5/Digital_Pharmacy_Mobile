class AgentCatalogItem {
  const AgentCatalogItem({required this.id, required this.value});

  final int id;
  final String value;

  bool get isSelectable =>
      id > 0 &&
      value.trim().isNotEmpty &&
      !const {'0', '?'}.contains(value.trim());

  factory AgentCatalogItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id =
        rawId is int
            ? rawId
            : rawId is String
            ? int.tryParse(rawId) ?? 0
            : 0;
    return AgentCatalogItem(id: id, value: (json['value'] ?? '').toString());
  }
}
