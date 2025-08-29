import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/bank_account_provider.dart';
import 'package:yo_te_pago/business/providers/currency_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/business/providers/remittance_provider.dart';
import 'package:yo_te_pago/presentation/widgets/dashboard/currency_vertical_listview_widget.dart';
import 'package:yo_te_pago/presentation/widgets/dashboard/remittance_vertical_listview_widget.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/shared/app_bar_widget.dart';


class DashboardView extends ConsumerStatefulWidget {

  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => DashboardViewState();

}


class DashboardViewState extends ConsumerState<DashboardView> {

  bool _dataLoadTriggered = false;

  Future<void> _loadDataOnceAuthenticated() async {
    if (_dataLoadTriggered) {
      return;
    }
    _dataLoadTriggered = true;

    try {
      await ref.read(currencyProvider.notifier).loadCurrencies();
      await ref.read(remittanceProvider.notifier).loadRemittances();
      await ref.read(accountProvider.notifier).loadAccounts();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Error al cargar datos del Dashboard',
          type: SnackBarType.error,
        );
      }
      _dataLoadTriggered = false;
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final authState = ref.read(authNotifierProvider);
      if (authState.isLoggedIn) {
        _loadDataOnceAuthenticated();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currenciesState = ref.watch(currencyProvider);
    final accountState = ref.watch(accountProvider);
    final remittancesState = ref.watch(remittanceProvider);
    final odooService = ref.read(odooServiceProvider);
    final userRole = ref.read(odooSessionNotifierProvider).session?.role;

    ref.listen<bool>(authNotifierProvider.select((auth) => auth.isLoggedIn), (prev, next) {
      if (next && !_dataLoadTriggered) {
        _loadDataOnceAuthenticated();
      }
    });
    if (!authState.isLoggedIn || currenciesState.isLoading || remittancesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (accountState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'Error al cargar cuentas de banco: ${accountState.errorMessage}',
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _dataLoadTriggered = false;
                _loadDataOnceAuthenticated();
              },
              child: const Text(AppButtons.retry),
            ),
          ],
        ),
      );
    }
    if (currenciesState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'Error al cargar monedas: ${currenciesState.errorMessage}',
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _dataLoadTriggered = false;
                _loadDataOnceAuthenticated();
              },
              child: const Text(AppButtons.retry),
            ),
          ],
        ),
      );
    }
    if (remittancesState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'Error al cargar remesas: ${remittancesState.errorMessage}',
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _dataLoadTriggered = false;
                _loadDataOnceAuthenticated();
              },
              child: const Text(AppButtons.retry),
            ),
          ],
        ),
      );
    }

    return Scaffold(
        floatingActionButton: userRole == 'delivery' ? FloatingActionButton(
          onPressed: () {
            context.go('/home/3');
          },
          tooltip: 'Remesar',
          child: const Icon(Icons.account_balance_wallet_outlined),
        ) : null,
        body: CustomScrollView(
          slivers: [

            SliverAppBar(
              floating: true,
              pinned: false,
              expandedHeight: 100.0,
              flexibleSpace: FlexibleSpaceBar(
                title: null,
                centerTitle: false,
                titlePadding: EdgeInsets.zero,
                background: Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: const CustomAppBar(),
                ),
              ),
            ),

            SliverList(
                delegate: SliverChildBuilderDelegate((context, index) => Column(
                    children: [

                      const SizedBox(height: 5),

                      RemittanceVerticalListView(
                        remittances: remittancesState.remittances,
                        currencies: currenciesState.currencies,
                        accounts: accountState.accounts
                      ),

                      const SizedBox(height: 10),

                      if (odooService.userRole == 'delivery')
                        CurrencyVerticalListView(
                          currencies: currenciesState.currencies,
                        )
                    ]
                ),
                    childCount: 1)
            )
          ]
        )
    );
  }

}
