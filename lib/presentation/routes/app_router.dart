import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/presentation/screens/home_screen.dart';
import 'package:yo_te_pago/presentation/screens/loading_screen.dart';
import 'package:yo_te_pago/presentation/screens/register_screen.dart';
import 'package:yo_te_pago/presentation/widgets/forms/balance_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/bank_account_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/rate_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/remittance_form_views.dart';


final appRouterProvider = Provider<GoRouter>((ref) {

  final authNotifier = ref.watch(authNotifierProvider);
  const String pathLoading = '/loading';
  const String pathHome = '/home/:page';
  const String pathRegister = '/register';
  const String pathRemittance = '/remittance/edit/:id';
  const String pathRemittanceCreate = '/remittance/create';
  const String pathRateCreate = '/rate/create';
  const String pathBalanceAdd = '/balance/create';
  const String pathBankAccountLink = '/account/link';

  String getHomePath(int pageIndex) => '/home/$pageIndex';

  return GoRouter(
    initialLocation: pathLoading,
    refreshListenable: authNotifier,

    routes: [
      GoRoute(
        path: pathLoading,
        builder: (context, state) => const LoadingScreen()
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home/0'
      ),
      GoRoute(
        path: pathHome,
        name: HomeScreen.name,
        builder: (context, state) {
          final pageIndex = int.tryParse(state.pathParameters['page'] ?? '0') ?? 0;

          return HomeScreen(pageIndex: pageIndex);
        },
      ),
      GoRoute(
        path: pathRegister,
        name: RegisterScreen.name,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: pathRemittance,
        name: RemittanceFormView.name,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0');

          return RemittanceFormView(id: id);
        },
      ),
      GoRoute(
        path: pathRemittanceCreate,
        name: 'create-remittance',
        builder: (context, state) => const RemittanceFormView(),
      ),
      GoRoute(
        path: pathRateCreate,
        name: RateFormView.name,
        builder: (context, state) => const RateFormView(),
      ),
      GoRoute(
        path: pathBalanceAdd,
        name: BalanceFormView.name,
        builder: (context, state) => const BalanceFormView(),
      ),
      GoRoute(
        path: pathBankAccountLink,
        name: BankAccountFormView.name,
        builder: (context, state) => const BankAccountFormView(),
      )
    ],

    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authNotifier.isLoggedIn;
      final isGoingToLoading = state.matchedLocation == pathLoading;

      if (!authNotifier.isInitialized) {
        return isGoingToLoading ? null : pathLoading;
      }
      final isGoingToRegister = state.matchedLocation == pathRegister;
      if (!isAuthenticated && !isGoingToRegister) {
        return pathRegister;
      }
      if (isAuthenticated && (isGoingToRegister || isGoingToLoading)) {
        return getHomePath(0);
      }

      return null;
    },

  );
});
