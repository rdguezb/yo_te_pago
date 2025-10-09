import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/presentation/routes/app_router.dart';
import 'package:yo_te_pago/presentation/screens/loading_screen.dart';
import 'package:yo_te_pago/presentation/theme/app_theme.dart';

class EntryPoint extends ConsumerWidget {

  const EntryPoint({super.key});

    @override
  Widget build(BuildContext context, WidgetRef ref) {

      final bool isInitialized = ref.watch(authNotifierProvider.select((state) => state.isInitialized));

      if (!isInitialized) {

        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LoadingScreen()
        );
      }

      final goRouter = ref.watch(appRouterProvider);

      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: goRouter
      );
  }

}
