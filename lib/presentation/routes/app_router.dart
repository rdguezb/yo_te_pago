import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/presentation/screens/home_screen.dart';
import 'package:yo_te_pago/presentation/screens/loading_screen.dart';
import 'package:yo_te_pago/presentation/screens/register_screen.dart';
import 'package:yo_te_pago/presentation/widgets/forms/balance_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/bank_account_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/profile_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/rate_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/remittance_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/under_construction_views.dart';


final appRouterProvider = Provider<GoRouter>((ref) {

  final authNotifier = ref.watch(authNotifierProvider);

  String getHomePath(int pageIndex) => '/home/$pageIndex';

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,

    routes: [
      GoRoute(
        path: AppRoutes.loadingUrl,
        builder: (context, state) => const LoadingScreen()
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home/0'
      ),
      GoRoute(
        path: AppRoutes.homeUrl,
        name: AppRoutes.home,
        builder: (context, state) {
          final pageIndex = int.tryParse(state.pathParameters['page'] ?? '0') ?? 0;

          return HomeScreen(pageIndex: pageIndex);
        },
      ),
      GoRoute(
        path: AppRoutes.registerUrl,
        name: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.remittanceEditUrl,
        name: AppRoutes.remittanceEdit,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0');

          return RemittanceFormView(id: id);
        },
      ),
      GoRoute(
        path: AppRoutes.remittanceCreateUrl,
        name: AppRoutes.remittanceCreate,
        builder: (context, state) => const RemittanceFormView(),
      ),
      GoRoute(
        path: AppRoutes.balanceUrl,
        name: AppRoutes.balance,
        builder: (context, state) => const BalanceFormView(),
      ),
      GoRoute(
        path: AppRoutes.rateUrl,
        name: AppRoutes.rate,
        builder: (context, state) => const RateFormView(),
      ),
      GoRoute(
        path: AppRoutes.accountUrl,
        name: AppRoutes.account,
        builder: (context, state) => const BankAccountFormView(),
      ),
      GoRoute(
        path: AppRoutes.profileUrl,
        name: AppRoutes.profile,
        builder: (context, state) => const ProfileFormView(),
      ),
      GoRoute(
        path: AppRoutes.passwordUrl,
        builder: (context, state) => const PlaceholderScreen(title: 'Cambiar Contraseña'),
      ),
      GoRoute(
        path: AppRoutes.usersUrl,
        builder: (context, state) => const PlaceholderScreen(title: 'Usuarios'),
      ),
      GoRoute(
        path: AppRoutes.currenciesUrl,
        builder: (context, state) => const PlaceholderScreen(title: 'Monedas'),
      ),
      GoRoute(
        path: AppRoutes.banksUrl,
        builder: (context, state) => const PlaceholderScreen(title: 'Bancos'),
      ),
      GoRoute(
        path: AppRoutes.bankAccountsUrl,
        builder: (context, state) => const PlaceholderScreen(title: 'Cuentas Bancarias'),
      ),
      GoRoute(
        path: AppRoutes.settingsUrl,
        builder: (context, state) => const PlaceholderScreen(title: 'Configuración'),
      ),
      GoRoute(
        path: AppRoutes.appUpdateUrl,
        name: 'app-update', // Es buena práctica añadir un nombre único
        builder: (context, state) => const PlaceholderScreen(title: 'Actualización'),
      ),
    ],

    redirect: (BuildContext context, GoRouterState state) {
      final isInitialized = authNotifier.isInitialized;
      final isAuthenticated = authNotifier.isLoggedIn;

      final isGoingToRegister = state.matchedLocation == AppRoutes.registerUrl;

      if (!isInitialized) {
        return null;
      }

      if (!isAuthenticated) {
        return isGoingToRegister ? null : AppRoutes.registerUrl;
      }

      if (isAuthenticated) {
        if (isGoingToRegister) {
          return getHomePath(0);
        }
      }

      return null;
    }

  );
});
