import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/helpers/human_formats.dart';


class TimePickerFormField extends StatefulWidget {

  final String? label;
  final String? hint;
  final String? errorMessage;
  final String? Function(String?)? validator;
  final bool isRequired;
  final bool enabled;
  final TextEditingController controller;

  const TimePickerFormField({
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
  State<TimePickerFormField> createState() => _TimePickerFormFieldState();

}

class _TimePickerFormFieldState extends State<TimePickerFormField> {

  TimeOfDay? _selectedTime;

  Future<void> _selectTime(BuildContext context) async {
    if (!widget.enabled) {
      return;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        widget.controller.text = picked.format(context);
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.controller.text.isNotEmpty) {
      try {
        _selectedTime = HumanFormats.tryTimeOfDay(widget.controller.text);
      } catch (e) {
        _selectedTime = null;
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
            focusedBorder: border.copyWith(borderSide: BorderSide(color: colors.primary)),
            errorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
            focusedErrorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
            isDense: true,
            label: widget.label != null ? Text(widget.label!) : null,
            hintText: widget.hint,
            errorText: widget.errorMessage,
            filled: widget.isRequired,
            focusColor: colors.primary,
            suffixIcon: IconButton(
              icon: const Icon(Icons.access_time),
              onPressed: widget.enabled ? () => _selectTime(context) : null,
            )
        )
    );
  }

}