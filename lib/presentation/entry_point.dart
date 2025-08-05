import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/providers/appdata_provider.dart';
import 'package:yo_te_pago/presentation/routes/app_router.dart';
import 'package:yo_te_pago/presentation/theme/app_theme.dart';


class MainApp extends ConsumerStatefulWidget {

  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();

}

class _MainAppState extends ConsumerState<MainApp> {

  @override
  void initState() {
    super.initState();

    ref.read(appDataProvider.notifier).loadAppDatas();
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
    );
  }

}
