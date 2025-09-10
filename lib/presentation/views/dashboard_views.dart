import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/business/providers/remittance_provider.dart';
import 'package:yo_te_pago/presentation/widgets/dashboard/remittance_tile.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/shared/app_bar_widget.dart';


class DashboardView extends ConsumerStatefulWidget {

  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => DashboardViewState();

}


class DashboardViewState extends ConsumerState<DashboardView> {

  final TextEditingController _searchController = TextEditingController();

  Future<void> _loadData() async {
    try {
      await ref.read(remittanceProvider.notifier).loadRemittances();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Error al cargar datos del Dashboard',
          type: SnackBarType.error,
        );
      }
    }
  }

  Widget? _buildFloatingActionButton(String? role) {

      if (role == ApiRole.delivery) {

        return FloatingActionButton(
            heroTag: 'addRemittance',
            onPressed: () => context.go('/remittance/create'),
            tooltip: 'Remesar',
            child: const Icon(Icons.add)
        );
      }
      else if (role == ApiRole.manager) {

        return FloatingActionButton(
            heroTag: 'recharge',
            onPressed: () {
  //   TODO Falta hacer el metodo
            },
            tooltip: 'Recargar',
            child: const Icon(Icons.shopify)
        );
      }

      return null;
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
    final authState = ref.watch(authNotifierProvider);
    final remittancesState = ref.watch(remittanceProvider);
    final userRole = ref.read(odooSessionNotifierProvider).session?.role;

    if (!authState.isLoggedIn || remittancesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (remittancesState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${remittancesState.errorMessage}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text(AppButtons.retry),
            ),
          ],
        ),
      );
    }
    final query = _searchController.text.toLowerCase();
    final filteredRemittances = remittancesState.remittances.where((remittance) {
      return remittance.customer.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
        floatingActionButton: _buildFloatingActionButton(userRole),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                          hintText: 'Buscar por cliente',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0)
                      )
                  )
              )
            ),

            if (filteredRemittances.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No se encontraron remesas!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red)
                  )
                )
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                    final remittance = filteredRemittances[index];

                    return RemittanceTile(
                      role: userRole,
                      remittance: remittance
                    );
                  },
                  childCount: filteredRemittances.length,
                ),
              ),
          ]
        )
    );
  }

}
