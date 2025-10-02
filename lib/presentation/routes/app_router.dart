import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/presentation/screens/home_screen.dart';
import 'package:yo_te_pago/presentation/screens/loading_screen.dart';
import 'package:yo_te_pago/presentation/screens/register_screen.dart';
import 'package:yo_te_pago/presentation/widgets/forms/balance_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/bank_account_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/my_account_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/rate_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/remittance_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/under_construction_views.dart';


final appRouterProvider = Provider<GoRouter>((ref) {

  final authNotifier = ref.watch(authNotifierProvider);

  const String loading = '/loading';
  const String home = '/home/:page';
  const String register = '/register';
  const String editRemittance = '/remittance/edit/:id';
  const String createRemittance = '/remittance/create';
  const String createRate = '/rate/create';
  const String createBalance = '/balance/create';
  const String linkBankAccount = '/account/link';

  const String myAccount = '/setting/account';
  const String myPassword = '/setting/password';
  const String users = '/setting/users';
  const String currencies = '/setting/currencies';
  const String banks = '/setting/banks';
  const String bankAccounts = '/setting/bank-accounts';
  const String settings = '/setting/settings';
  const String appUpdate = '/setting/app-update';

  String getHomePath(int pageIndex) => '/home/$pageIndex';

  return GoRouter(
    initialLocation: loading,
    refreshListenable: authNotifier,

    routes: [
      GoRoute(
        path: loading,
        builder: (context, state) => const LoadingScreen()
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home/0'
      ),
      GoRoute(
        path: home,
        name: HomeScreen.name,
        builder: (context, state) {
          final pageIndex = int.tryParse(state.pathParameters['page'] ?? '0') ?? 0;

          return HomeScreen(pageIndex: pageIndex);
        },
      ),
      GoRoute(
        path: register,
        name: RegisterScreen.name,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: editRemittance,
        name: RemittanceFormView.name,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0');

          return RemittanceFormView(id: id);
        },
      ),
      GoRoute(
        path: createRemittance,
        name: 'create-remittance',
        builder: (context, state) => const RemittanceFormView(),
      ),
      GoRoute(
        path: createRate,
        name: RateFormView.name,
        builder: (context, state) => const RateFormView(),
      ),
      GoRoute(
        path: createBalance,
        name: BalanceFormView.name,
        builder: (context, state) => const BalanceFormView(),
      ),
      GoRoute(
        path: linkBankAccount,
        name: BankAccountFormView.name,
        builder: (context, state) => const BankAccountFormView(),
      ),
      GoRoute(
        path: myAccount,
        name: MyAccountFormView.name,
        builder: (context, state) => const MyAccountFormView(),
      ),
      GoRoute(
        path: myPassword,
        builder: (context, state) => const PlaceholderScreen(title: 'Cambiar Contraseña'),
      ),
      GoRoute(
        path: users,
        builder: (context, state) => const PlaceholderScreen(title: 'Usuarios'),
      ),
      GoRoute(
        path: currencies,
        builder: (context, state) => const PlaceholderScreen(title: 'Monedas'),
      ),
      GoRoute(
        path: banks,
        builder: (context, state) => const PlaceholderScreen(title: 'Bancos'),
      ),
      GoRoute(
        path: bankAccounts,
        builder: (context, state) => const PlaceholderScreen(title: 'Cuentas Bancarias'),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const PlaceholderScreen(title: 'Configuración'),
      ),
      GoRoute(
        path: appUpdate,
        name: 'app-update', // Es buena práctica añadir un nombre único
        builder: (context, state) => const PlaceholderScreen(title: 'Actualización'),
      ),
    ],

    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authNotifier.isLoggedIn;
      final isGoingToLoading = state.matchedLocation == loading;

      if (!authNotifier.isInitialized) {
        return isGoingToLoading ? null : loading;
      }
      final isGoingToRegister = state.matchedLocation == register;
      if (!isAuthenticated && !isGoingToRegister) {
        return register;
      }
      if (isAuthenticated && (isGoingToRegister || isGoingToLoading)) {
        return getHomePath(0);
      }

      return null;
    },

  );
});
