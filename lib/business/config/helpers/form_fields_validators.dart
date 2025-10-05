import 'package:yo_te_pago/business/config/constants/app_validation.dart';


class FormValidators {

  static String? validateRequired(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? AppValidationMessages.required;
    }

    return null;
  }

  static String? validateDouble(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? AppValidationMessages.required;
    }

    final number = double.tryParse(value);
    if (number == null) {
      return AppValidationMessages.invalidNumber;
    }
    if (number <= 0) {
      return AppValidationMessages.positiveNumber;
    }

    return null;
  }

}