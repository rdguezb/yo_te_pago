import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/balances_provider.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/balance_tile.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class ReportView extends ConsumerStatefulWidget {

  const ReportView({super.key});

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();

}


class _ReportViewState extends ConsumerState<ReportView> {

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    Future.microtask(() => _loadData());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final balancesState = ref.watch(balanceProvider);
    final userRole = authState.session?.role;

    if (!authState.isLoggedIn || balancesState.isLoading ) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredBalances = balancesState.filteredBalances;

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
                                  balancesState.errorMessage.toString(),
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
                  else ...[
                    if (userRole != ApiRole.delivery)
                      SliverToBoxAdapter(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: TextFormField(
                                  controller: _searchController,
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

                    const SliverPadding(
                      padding: EdgeInsets.symmetric(vertical: 16.0)
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
                ]
            )
        )
      )
    );
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadData() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(balanceProvider.notifier).loadBalances();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Error al cargar datos del Balance',
          type: SnackBarType.error,
        );
      }
    }
  }

}
