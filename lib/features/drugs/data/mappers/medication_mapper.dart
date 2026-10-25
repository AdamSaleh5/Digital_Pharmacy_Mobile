import '../../../../data/models/drug.dart';
import '../models/medication_item.dart';

class MedicationMapper {
  static Drug toDrug(MedicationItem item) {
    final dosageForms =
        item.pharmaceuticalForm.trim().isEmpty
            ? <DosageFormPrice>[]
            : [
              DosageFormPrice(
                formName: item.pharmaceuticalForm,
                priceJod: item.price,
                priceCurrencyKnown: false,
              ),
            ];
    return Drug(
      id: item.id.toString(),
      brandName: item.tradeName,
      scientificName: item.scientificName,
      company: item.company,
      agentName: item.agent,
      agentNumber: item.agentsPhoneNumber,
      dosageForms: dosageForms,
      strength: '',
      usage: item.usage,
      priceJod: item.price,
      priceCurrencyKnown: false,
      alternatives: '',
      // Catalog responses do not establish a numeric country mapping.
      country: '',
    );
  }
}
