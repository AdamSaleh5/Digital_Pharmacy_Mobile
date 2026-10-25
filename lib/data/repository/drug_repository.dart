import '../../core/models/drug_search_mode.dart';
import '../datasource/mock_drugs.dart';
import '../models/drug.dart';

class DrugRepository {
  const DrugRepository();

  List<Drug> getAll() => MockDrugs.all;

  List<Drug> search({
    required String query,
    DrugSearchMode mode = DrugSearchMode.all,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return MockDrugs.all;

    Iterable<String> fieldsForMode(Drug d) {
      switch (mode) {
        case DrugSearchMode.scientific:
          return [d.scientificName];
        case DrugSearchMode.trade:
          return [d.brandName];
        case DrugSearchMode.company:
          return [d.company];
        case DrugSearchMode.agent:
          return [d.agentName];
        case DrugSearchMode.all:
          return [d.brandName, d.scientificName, d.company, d.agentName];
      }
    }

    bool matches(Drug d) {
      final fields = fieldsForMode(d).map((e) => e.toLowerCase());
      return fields.any((value) => value.contains(q));
    }

    int score(Drug d) {
      final exactFields = fieldsForMode(d).map((e) => e.toLowerCase());

      if (exactFields.any((value) => value == q)) return 0;
      if (exactFields.any((value) => value.startsWith(q))) return 1;
      if (exactFields.any((value) => value.contains(q))) return 2;
      return 3;
    }

    final results = MockDrugs.all.where(matches).toList();
    results.sort((a, b) => score(a).compareTo(score(b)));
    return results;
  }

  List<String> getUniqueAgents({String query = ''}) {
    return _uniqueValues(
      selector: (d) => d.agentName,
      query: query,
    );
  }

  List<String> getUniqueCompanies({String query = ''}) {
    return _uniqueValues(
      selector: (d) => d.company,
      query: query,
    );
  }

  List<String> getUniqueTradeNames({String query = ''}) {
    return _uniqueValues(
      selector: (d) => d.brandName,
      query: query,
    );
  }

  List<String> getUniqueScientificNames({String query = ''}) {
    return _uniqueValues(
      selector: (d) => d.scientificName,
      query: query,
    );
  }

  List<Drug> getDrugsByAgent(String agentName) {
    return _filterByExactMatch(
      value: agentName,
      accessor: (d) => d.agentName,
    );
  }

  List<Drug> getDrugsByCompany(String companyName) {
    return _filterByExactMatch(
      value: companyName,
      accessor: (d) => d.company,
    );
  }

  List<Drug> getDrugsByTrade(String tradeName) {
    return _filterByExactMatch(
      value: tradeName,
      accessor: (d) => d.brandName,
    );
  }

  List<Drug> getDrugsByScientificName(String scientificName) {
    return _filterByExactMatch(
      value: scientificName,
      accessor: (d) => d.scientificName,
    );
  }

  Drug? byId(String id) {
    for (final d in MockDrugs.all) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<Drug> alternativesSameScientific(String scientificName, {required String excludeId}) {
    final target = scientificName.trim().toLowerCase();
    return MockDrugs.all
        .where((d) => d.scientificName.trim().toLowerCase() == target && d.id != excludeId)
        .toList();
  }

  List<String> _uniqueValues({
    required String Function(Drug) selector,
    required String query,
  }) {
    final q = query.trim().toLowerCase();
    final set = <String>{};
    for (final drug in MockDrugs.all) {
      final value = selector(drug).trim();
      if (value.isEmpty) continue;
      if (q.isEmpty || value.toLowerCase().contains(q)) {
        set.add(value);
      }
    }
    final list = set.toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  List<Drug> _filterByExactMatch({
    required String value,
    required String Function(Drug) accessor,
  }) {
    final target = value.trim().toLowerCase();
    final results = MockDrugs.all.where(
      (drug) => accessor(drug).trim().toLowerCase() == target,
    );
    final list = results.toList();
    list.sort((a, b) => a.brandName.compareTo(b.brandName));
    return list;
  }
}
