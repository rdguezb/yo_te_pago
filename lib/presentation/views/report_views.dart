import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/balance_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/widgets/reports/balance_tile.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class ReportView extends ConsumerStatefulWidget {

  const ReportView({super.key});

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();

}


class _ReportViewState extends ConsumerState<ReportView> {

  final TextEditingController _searchController = TextEditingController();

  Future<void> _loadData() async {
    try {
      await ref.read(balanceProvider.notifier).loadBalances();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Error al cargar datos del Balance',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() => _loadData());
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.removeListener(() {});
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final balancesState = ref.watch(balanceProvider);
    final userRole = ref.read(odooSessionNotifierProvider).session?.role;

    if (!authState.isLoggedIn || balancesState.isLoading ) {
      return const Center(child: CircularProgressIndicator());
    }

    final query = _searchController.text.toLowerCase();
    final filteredBalances = balancesState.balances.where((balance) {
      return balance.partnerName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTitles.reports),
        centerTitle: true
      ),
        floatingActionButton: (userRole == ApiRole.manager)
            ? FloatingActionButton(
                  heroTag: 'addMoney',
                  onPressed: () => context.go('/balance/create'),
                  tooltip: 'Agregar saldo',
                  child: const Icon(
                      Icons.shopify_outlined,
                      size: 40)
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: CustomScrollView(
                slivers: [

                  SliverToBoxAdapter(
                      child: Center(
                          child: Icon(
                              Icons.query_stats,
                              color: colors.primary,
                              size: 60
                          )
                      )
                  ),

                  const SliverPadding(
                      padding: EdgeInsets.symmetric(vertical: 16.0)
                  ),

                  if (balancesState.errorMessage != null)
                    SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                  '${balancesState.errorMessage}',
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => _loadData(),
                                child: const Text(AppButtons.retry)
                              )
                            ]
                          )
                        )
                    )
                  else
                    if (userRole != ApiRole.delivery)
                      SliverToBoxAdapter(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: TextFormField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                      hintText: 'Buscar por remesero',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0)
                                  )
                              )
                          )
                      ),
                  if (filteredBalances.isEmpty)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Text(
                                'No se encontraron saldos!',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red)
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
    );
  }

}