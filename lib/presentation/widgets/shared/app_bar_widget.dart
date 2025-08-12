import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/configs.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';


class CustomAppBar extends ConsumerWidget {

  const CustomAppBar({super.key});

  static const String _currentVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styles = Theme.of(context).textTheme;
    final odooService = ref.watch(odooServiceProvider);
    final String userName = odooService.partnerName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/icon-app.png',
            width: 60,
            height: 60,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppConfig.name,
                  style: styles.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
                Text(
                  _currentVersion,
                  style: styles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              ]
            )
          ),
          Text(
            userName,
            style: styles.titleLarge,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1)
        ]
      )
    );
  }

}