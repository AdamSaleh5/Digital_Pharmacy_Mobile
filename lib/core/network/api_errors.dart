import 'package:dio/dio.dart';
import 'package:digitalpharmacy/l10n/app_localizations.dart';

import 'api_service.dart';

String apiFailureMessage(Object error, AppLocalizations l10n) {
  if (error is ApiContractUnavailable) return l10n.apiContractUnavailable;
  if (error is FormatException || error is StateError) {
    return l10n.apiContractUnavailable;
  }
  if (error is DioException &&
      const {401, 403}.contains(error.response?.statusCode)) {
    return l10n.apiAuthenticationRequired;
  }
  return l10n.errorLoadingData;
}

bool isApiFailureRetryable(Object error) {
  if (error is ApiContractUnavailable) return false;
  if (error is FormatException ||
      error is StateError ||
      error is ArgumentError) {
    return false;
  }
  return true;
}
