import 'package:flutter/material.dart';


class ComboBoxPicker extends StatelessWidget {

  final String hint;
  final String label;
  final bool isRequired;
  final String? selectedId;
  final String? Function( String? )? validator;
  final ValueChanged<String?>? onChanged;
  final List<DropdownMenuItem<String>> items;
  final bool enabled;

  const ComboBoxPicker({
    super.key,
    required this.hint,
    required this.label,
    required this.isRequired,
    this.selectedId,
    required this.items,
    this.validator,
    this.enabled = true,
    this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(5.0));
    final colors = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      value: selectedId,
      hint: Text(hint),
      decoration: InputDecoration(
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: colors.primary)),
        errorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        focusedErrorBorder: border.copyWith(borderSide: BorderSide(color: Colors.red.shade800)),
        isDense: true,
        label: Text(label),
        filled: isRequired || !enabled,
        fillColor: enabled ? colors.surfaceContainerHighest : colors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      icon: Icon(
          Icons.arrow_drop_down,
          color: enabled ? colors.onSurfaceVariant : Theme.of(context).disabledColor
      ),
    );
  }

}
