class MedicalReferenceLink {
  final String label;
  final String url;

  const MedicalReferenceLink({required this.label, required this.url});
}

String _normalizedMedicalQuery(String scientificName, String tradeName) {
  final scientific = scientificName.trim();
  if (scientific.isNotEmpty) return scientific;
  return tradeName.trim();
}

List<MedicalReferenceLink> buildMedicalReferenceLinks({
  required String scientificName,
  required String tradeName,
  required String dailyMedLabel,
  required String medlinePlusLabel,
  required String nhsLabel,
}) {
  final query = Uri.encodeQueryComponent(
    _normalizedMedicalQuery(scientificName, tradeName),
  );

  return [
    MedicalReferenceLink(
      label: dailyMedLabel,
      url: 'https://dailymed.nlm.nih.gov/dailymed/search.cfm?query=$query',
    ),
    MedicalReferenceLink(
      label: medlinePlusLabel,
      url: 'https://medlineplus.gov/search/?query=$query',
    ),
    MedicalReferenceLink(
      label: nhsLabel,
      url: 'https://www.nhs.uk/search/results?q=$query',
    ),
  ];
}
