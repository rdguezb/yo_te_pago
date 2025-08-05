import 'package:flutter/material.dart';


class FancyText extends StatelessWidget {

  final String messageText;
  final Color? color;
  final IconData iconData;

  const FancyText({
    super.key,
    required this.messageText,
    required this.iconData,
    this.color
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.onSurface;
    final textColor = color ?? theme.textTheme.headlineSmall?.color ?? theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        children: [
          Icon(
              iconData,
              color: iconColor
          ),
          const SizedBox(height: 10),
          Text(
            messageText,
            style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }

}