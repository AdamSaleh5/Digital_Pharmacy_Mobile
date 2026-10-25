enum AppCountry { jordan, palestine }

class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'DIGITAL_PHARMACY_API_BASE_URL',
    defaultValue: 'http://144.91.111.63:5002',
  );

  /// Same-origin HTTPS verification for the separate legacy admin service.
  /// Public catalog GETs remain available on the configured HTTP origin.
  static const verifiedAuthOrigin = String.fromEnvironment(
    'DIGITAL_PHARMACY_VERIFIED_API_ORIGIN',
    defaultValue: '',
  );
}

AppCountry _currentCountry = AppCountry.jordan;
int _countryRevision = 0;
int get appCountryRevision => _countryRevision;

AppCountry get kAppCountry => _currentCountry;

void setAppCountry(AppCountry country) {
  if (_currentCountry == country) return;
  _currentCountry = country;
  _countryRevision++;
}

AppCountry? appCountryFromCode(String? code) {
  switch (code?.toUpperCase()) {
    case 'JO':
      return AppCountry.jordan;
    case 'PS':
      return AppCountry.palestine;
    default:
      return null;
  }
}

String appCountryStorageValue(AppCountry country) {
  return country.name;
}

AppCountry? appCountryFromStorage(String? value) {
  switch (value) {
    case 'jordan':
      return AppCountry.jordan;
    case 'palestine':
      return AppCountry.palestine;
    default:
      return null;
  }
}

String appCountryNameAr(AppCountry country) {
  return country == AppCountry.jordan ? 'الأردن' : 'فلسطين';
}

String appCountryNameEn(AppCountry country) {
  return country == AppCountry.jordan ? 'Jordan' : 'Palestine';
}

String appCurrencySymbol([AppCountry? country]) {
  final target = country ?? kAppCountry;
  return target == AppCountry.jordan ? 'د.أ' : '₪';
}

String formatPriceByCountry(double amount, [AppCountry? country]) {
  return '${amount.toStringAsFixed(2)} ${appCurrencySymbol(country)}';
}

String apiCountryString([AppCountry? country]) {
  final target = country ?? kAppCountry;
  return target == AppCountry.jordan ? 'Jordan' : 'Palestine';
}

enum MedicationSearchType { tradeName, scientificName }

extension MedicationSearchTypeMapper on MedicationSearchType {
  String asString() {
    switch (this) {
      case MedicationSearchType.tradeName:
        return 'TradeName'.trim();
      case MedicationSearchType.scientificName:
        return 'ScientificName'.trim();
    }
  }

  String asNumber() {
    switch (this) {
      case MedicationSearchType.tradeName:
        return '1';
      case MedicationSearchType.scientificName:
        return '2';
    }
  }
}

enum PharmacySearchType { name, address, managerName, phoneNumber }

extension PharmacySearchTypeMapper on PharmacySearchType {
  String asString() {
    switch (this) {
      case PharmacySearchType.name:
        return 'Name'.trim();
      case PharmacySearchType.address:
        return 'Address'.trim();
      case PharmacySearchType.managerName:
        return 'ManagerName'.trim();
      case PharmacySearchType.phoneNumber:
        return 'PhoneNumber'.trim();
    }
  }

  String asNumber() {
    switch (this) {
      case PharmacySearchType.name:
        return '1';
      case PharmacySearchType.address:
        return '2';
      case PharmacySearchType.managerName:
        return '3';
      case PharmacySearchType.phoneNumber:
        return '4';
    }
  }
}
