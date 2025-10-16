import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/domain/entities/bank.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/presentation/screens/home_screen.dart';
import 'package:yo_te_pago/presentation/screens/loading_screen.dart';
import 'package:yo_te_pago/presentation/screens/register_screen.dart';
import 'package:yo_te_pago/presentation/views/settings/bank_account_views.dart';
import 'package:yo_te_pago/presentation/views/settings/banks_views.dart';
import 'package:yo_te_pago/presentation/views/settings/currencies_views.dart';
import 'package:yo_te_pago/presentation/views/settings/users_view.dart';
import 'package:yo_te_pago/presentation/widgets/forms/balance_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/account_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/settings/bank_account_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/settings/bank_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/settings/profile_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/rate_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/remittance_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/forms/settings/setting_form_views.dart';
import 'package:yo_te_pago/presentation/widgets/under_construction_views.dart';


final appRouterProvider = Provider<GoRouter>((ref) {

  final authNotifier = ref.watch(authNotifierProvider);

  String getHomePath(int pageIndex) => '/home/$pageIndex';

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,

    routes: [
      GoRoute(
        name: AppRoutes.loading,
        path: AppRoutes.loadingUrl,
        builder: (context, state) => const LoadingScreen()
      ),
      GoRoute(
        name: AppRoutes.dashboard,
        path: AppRoutes.dashboardUrl,
        redirect: (_, __) => '/home/0'
      ),
      GoRoute(
          name: AppRoutes.register,
          path: AppRoutes.registerUrl,
          builder: (context, state) => const RegisterScreen()
      ),
      GoRoute(
        name: AppRoutes.home,
        path: AppRoutes.homeUrl,
        builder: (context, state) {
          final pageIndex = int.tryParse(state.pathParameters['page'] ?? '0') ?? 0;

          return HomeScreen(pageIndex: pageIndex);
        }
      ),
      GoRoute(
        name: AppRoutes.remittance,
        path: AppRoutes.remittanceUrl,
        builder: (context, state) {
          final remittance = state.extra as Remittance?;
          return RemittanceFormView(remittance: remittance);
        }
      ),
      GoRoute(
        name: AppRoutes.balance,
        path: AppRoutes.balanceUrl,
        builder: (context, state) => const BalanceFormView()
      ),
      GoRoute(
        name: AppRoutes.rate,
        path: AppRoutes.rateUrl,
        builder: (context, state) => const RateFormView()
      ),
      GoRoute(
        name: AppRoutes.account,
        path: AppRoutes.accountUrl,
        builder: (context, state) => const AccountFormView()
      ),
      GoRoute(
        name: AppRoutes.profile,
        path: AppRoutes.profileUrl,
        builder: (context, state) => const ProfileFormView()
      ),
      GoRoute(
        name: AppRoutes.settings,
        path: AppRoutes.settingsUrl,
        builder: (context, state) => const SettingsFormView()
      ),
      GoRoute(
        name: AppRoutes.banks,
        path: AppRoutes.banksUrl,
        builder: (context, state) => const BankViews()
      ),
      GoRoute(
        name: AppRoutes.banksCreate,
        path: AppRoutes.bankCreateUrl,
        builder: (context, state) {
          final bank = state.extra as Bank?;

          return BanksFormView(bank: bank);
        }
      ),
      GoRoute(
        name: AppRoutes.bankAccount,
        path: AppRoutes.bankAccountsUrl,
        builder: (context, state) => const BankAccountViews(),
      ),
      GoRoute(
        name: AppRoutes.bankAccountCreate,
        path: AppRoutes.bankAccountCreateUrl,
        builder: (context, state) {
          final bankAccount = state.extra as BankAccount?;

          return BankAccountFormView(bankAccount: bankAccount);
        },
      ),
      GoRoute(
        name: AppRoutes.currency,
        path: AppRoutes.currenciesUrl,
        builder: (context, state) => const CurrenciesView(),
      ),

      GoRoute(
        name: AppRoutes.password,
        path: AppRoutes.passwordUrl,
        builder: (context, state) => const PlaceholderScreen(title: 'Cambiar Contraseña'),
      ),
      GoRoute(
        name: AppRoutes.users,
        path: AppRoutes.usersUrl,
        builder: (context, state) => const UsersView(),
      ),
      GoRoute(
        name: AppRoutes.appUpdate,
        path: AppRoutes.appUpdateUrl,
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
