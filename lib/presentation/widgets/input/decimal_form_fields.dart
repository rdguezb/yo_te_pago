import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:yo_te_pago/business/config/constants/formats.dart';


class DecimalTextFormField extends StatelessWidget {

  final String? label;
  final String? hint;
  final String? errorMessage;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool enabled;

  final maxDecimalDigits = AppFormats.maxDecimalDigits;


  const DecimalTextFormField({
    super.key,
    this.label,
    this.hint,
    this.errorMessage,
    this.controller,
    this.onChanged,
    this.validator,
    this.isRequired = false,
    this.enabled = true
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(5.0));

    return TextFormField(
      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: false),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('^\\d*\\.?\\d{0,$maxDecimalDigits}\$'))
      ],
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
          enabledBorder: border,
          focusedBorder: border.copyWith(borderSide: BorderSide(color: colors.primary)),
          errorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
          focusedErrorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
          isDense: true,
          label: label != null ? Text(label!) : null,
          hintText: hint,
          errorText: errorMessage,
          filled: isRequired,
          focusColor: colors.primary
      ),
    );
  }

}