import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/configs.dart';
import 'package:yo_te_pago/business/config/helpers/human_formats.dart';


class DatePickerFormField extends StatefulWidget {

  final String? label;
  final String? hint;
  final String? errorMessage;
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool enabled;
  final TextEditingController controller;

  const DatePickerFormField({
    super.key,
    this.label,
    this.hint,
    this.errorMessage,
    this.validator,
    this.isRequired = false,
    this.enabled = true,
    required this.controller
  });

  @override
  State<DatePickerFormField> createState() => _DatePickerFormFieldState();

}

class _DatePickerFormFieldState extends State<DatePickerFormField> {

  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    if (!widget.enabled) {
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(AppConfig.minYear),
      lastDate: DateTime(AppConfig.maxYear),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        widget.controller.text = HumanFormats.toShortDate(picked);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.controller.text.isNotEmpty) {
      try {
        _selectedDate = HumanFormats.toDateTime(widget.controller.text);
      } catch (e) {
        _selectedDate = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(5.0));

    return TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        readOnly: true,
        enabled: widget.enabled,
        decoration: InputDecoration(
            enabledBorder: border,
            focusedBorder: border.copyWith( borderSide: BorderSide(color: colors.primary)),
            errorBorder: border.copyWith( borderSide: BorderSide(color: Colors.red.shade800)),
            focusedErrorBorder: border.copyWith( borderSide: BorderSide(color: Colors.red.shade800)),
            isDense: true,
            label: widget.label != null ? Text(widget.label!) : null,
            hintText: widget.hint,
            errorText: widget.errorMessage,
            filled: widget.isRequired,
            focusColor: colors.primary,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: widget.enabled ? () => _selectDate(context) : null,
            )
        )
    );
  }

}