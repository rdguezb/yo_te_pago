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

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppValidationMessages.required;
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return AppValidationMessages.invalidEmail;
    }

    return null;
  }

}
