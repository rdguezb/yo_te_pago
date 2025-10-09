import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:yo_te_pago/business/config/constants/configs.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';


final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

class CustomAppBar extends ConsumerWidget {

  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styles = Theme.of(context).textTheme;
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.session?.partnerName ?? 'Invitado';
    final packageInfoAsync = ref.watch(packageInfoProvider);

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
                packageInfoAsync.when(
                  data: (info) => Text(
                      'v${info.version}',
                      style: styles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => Text(
                    'Error',
                    style: styles.bodySmall,
                  ),
                )
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