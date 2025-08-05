import 'package:yo_te_pago/business/config/constants/validation_messages.dart';


class FormValidators {

  static String? validateRequired(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? AppValidation.required;
    }

    return null;
  }

  static String? validateInteger(String? value, {String? errorMessage}) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage ?? AppValidation.required;
    }

    final number = double.tryParse(value);
    if (number == null) {
      return AppValidation.invalidNumber;
    }
    if (number <= 0) {
      return AppValidation.positiveNumber;
    }

    return null;
  }

}