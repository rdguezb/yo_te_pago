import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/forms.dart';


class ConfirmModalDialog extends StatelessWidget {

  final String title;
  final String content;
  final String confirmButtonText;
  final String cancelButtonText;
  final Color? confirmButtonColor;

  const ConfirmModalDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmButtonText = AppButtons.confirm,
    this.cancelButtonText = AppButtons.cancel,
    this.confirmButtonColor
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelButtonText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmButtonText,
            style: TextStyle(
              color: confirmButtonColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

}