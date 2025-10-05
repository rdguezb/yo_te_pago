import 'package:flutter/material.dart';


enum SnackBarType {
  success,
  error,
  warning,
  info,
}

class _ColorScheme {

  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final Color actionColor;

  _ColorScheme({
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.actionColor,
  });

}

IconData _getIconData(SnackBarType type) {
  switch (type) {
    case SnackBarType.success:
      return Icons.check_circle;
    case SnackBarType.error:
      return Icons.error;
    case SnackBarType.warning:
      return Icons.warning;
    case SnackBarType.info:
      return Icons.info;
  }
}

_ColorScheme _getColorScheme(ThemeData theme, SnackBarType type) {
  switch (type) {
    case SnackBarType.success:
      return _ColorScheme(
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
        iconColor: Colors.white,
        actionColor: Colors.white70,
      );
    case SnackBarType.error:
      return _ColorScheme(
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
        iconColor: Colors.white,
        actionColor: Colors.white70,
      );
    case SnackBarType.warning:
      return _ColorScheme(
        backgroundColor: Colors.orange.shade600,
        textColor: Colors.white,
        iconColor: Colors.white,
        actionColor: Colors.white70,
      );
    case SnackBarType.info:
      return _ColorScheme(
          backgroundColor: theme.colorScheme.primary,
          textColor: theme.colorScheme.onPrimary,
          iconColor: theme.colorScheme.onPrimary,
          actionColor: theme.colorScheme.onPrimary.withAlpha((255 * 0.8).round())
        );
  }
}

class CustomSnackBarContent extends StatelessWidget {

  final String message;
  final SnackBarType type;
  final ThemeData theme;

  const CustomSnackBarContent({
    super.key,
    required this.message,
    required this.type,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getColorScheme(theme, type);

    return Row(
      children: [
        Icon(
          _getIconData(type),
          color: colorScheme.iconColor,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            message,
            style: TextStyle(color: colorScheme.textColor),
          ),
        ),
      ],
    );
  }

}

void showCustomSnackBar({
  required ScaffoldMessengerState scaffoldMessenger,
  required String message,
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onActionPressed
}) {
  scaffoldMessenger.hideCurrentSnackBar();

  final BuildContext context = scaffoldMessenger.context;
  final ThemeData theme = Theme.of(context);
  final _ColorScheme colorScheme = _getColorScheme(theme, type);

  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: CustomSnackBarContent(
        message: message,
        type: type,
        theme: theme
      ),
      backgroundColor: colorScheme.backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0)),
      duration: duration,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: colorScheme.actionColor,
              onPressed: onActionPressed ?? () {}
            )
          : null
    )
  );
}