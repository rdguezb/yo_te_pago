import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/presentation/screens/home_screen.dart';
import 'package:yo_te_pago/presentation/screens/loading_screen.dart';
import 'package:yo_te_pago/presentation/screens/register_screen.dart';
import 'package:yo_te_pago/presentation/views/remittance_views.dart';


final appRouterProvider = Provider<GoRouter>((ref) {

  final authNotifier = ref.watch(authNotifierProvider);
  const String homePath = '/home/:page';
  const String registerPath = '/register';
  const String remittancePath = '/remittance/edit/:id';

  String getHomePath(int pageIndex) => '/home/$pageIndex';

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (!authNotifier.isInitialized) {
            return const LoadingScreen();
          }

          return authNotifier.isLoggedIn
              ? HomeScreen(pageIndex: 0)
              : const RegisterScreen();
        },
      ),
      GoRoute(
        path: homePath,
        name: HomeScreen.name,
        builder: (context, state) {
          final pageIndex = int.tryParse(state.pathParameters['page'] ?? '0') ?? 0;

          return HomeScreen(pageIndex: pageIndex);
        },
      ),
      GoRoute(
        path: registerPath,
        name: RegisterScreen.name,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: remittancePath,
        name: RemittanceView.name,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0');
          return RemittanceView(
            id: id
          );
        },
      ),
    ],

    redirect: (BuildContext context, GoRouterState state) {
      if (!authNotifier.isInitialized) {
        return null;
      }
      final isAuthenticated = authNotifier.isLoggedIn;
      final isGoingToRegister = state.uri.path == registerPath;

      if (!isAuthenticated && !isGoingToRegister) {
        return registerPath;
      }

      if (isAuthenticated && isGoingToRegister) {
        return getHomePath(0);
      }

      return null;
    },

  );
});
