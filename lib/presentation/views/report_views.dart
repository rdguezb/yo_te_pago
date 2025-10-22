import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/balances_provider.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/balance_tile.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class ReportView extends ConsumerStatefulWidget {

  static const name = 'balance';

  const ReportView({super.key});

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();

}


class _ReportViewState extends ConsumerState<ReportView> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(balanceProvider).balances.isEmpty) {
        ref.read(balanceProvider.notifier).loadBalances();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authState = ref.watch(authNotifierProvider);
    final balancesState = ref.watch(balanceProvider);
    final userRole = authState.session?.user.roleName;
    final filteredBalances = balancesState.filteredBalances;

    ref.listen(balanceProvider, (previous, next) {
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: next.errorMessage!,
          type: SnackBarType.error
        );
      }
      if (next.lastUpdateSuccess && previous?.lastUpdateSuccess == false) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.operationSuccess, // Mensaje genérico de éxito
          type: SnackBarType.success
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTitles.reports),
        centerTitle: true
      ),
        floatingActionButton: (userRole == ApiRole.manager)
            ? FloatingActionButton(
                  heroTag: 'addMoney',
                  onPressed: () => context.pushNamed(AppRoutes.balance),
                  tooltip: 'Agregar saldo',
                  child: const Icon(
                      Icons.shopify_outlined,
                      size: 40)
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(balanceProvider.notifier).refreshBalances(),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    SliverToBoxAdapter(
                        child: Center(
                            child: Icon(
                                Icons.query_stats,
                                color: colors.primary,
                                size: 60
                            )
                        )
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    if (userRole != ApiRole.delivery)
                      SliverToBoxAdapter(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                  onChanged: (query) {
                                    ref.read(balanceProvider.notifier).setSearchQuery(query);
                                  },
                                  decoration: InputDecoration(
                                      hintText: AppFormLabels.hintCustomerSearch,
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0)
                                  )
                              )
                          )
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    if (balancesState.isLoading && filteredBalances.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator())
                      )
                    else if (balancesState.errorMessage != null && filteredBalances.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    balancesState.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: colors.error)
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                      onPressed: () => ref.read(balanceProvider.notifier).refreshBalances(),
                                      child: const Text(AppButtons.retry)
                                  )
                                ]
                            )
                        )
                      )
                    else if (filteredBalances.isEmpty)
                        SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                                child: Text(
                                  'No se encontraron saldos',
                                  style: Theme.of(context).textTheme.titleMedium
                                )
                            )
                        )
                      else
                        SliverList(
                            delegate: SliverChildBuilderDelegate(
                                    (BuildContext context, int index) {
                                  final balance = filteredBalances[index];
                                  return BalanceTile(
                                      role: userRole,
                                      balance: balance
                                  );
                                },
                                childCount: filteredBalances.length
                            )
                        )
                  ]
              )
          )
        )
      )
    );
  }

}
