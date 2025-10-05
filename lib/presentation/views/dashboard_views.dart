import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/remittance_provider.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/remittance_tile.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/shared/app_bar_widget.dart';


class DashboardView extends ConsumerStatefulWidget {

  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => DashboardViewState();

}


class DashboardViewState extends ConsumerState<DashboardView> {

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
    final authState = ref.watch(authNotifierProvider);
    final remittancesState = ref.watch(remittanceProvider);
    final userRole = authState.session?.role;

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
    final filteredRemittances = remittancesState.filteredRemittances;

    return Scaffold(
        floatingActionButton: userRole == ApiRole.delivery
            ? FloatingActionButton(
            heroTag: 'addRemittance',
            onPressed: () => context.go('/remittance/create'),
            tooltip: 'Remesar',
            child: const Icon(Icons.add))
        : null,
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
                      onChanged: (query) {
                        ref.read(remittanceProvider.notifier).setSearchQuery(query);
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
      await ref.read(remittanceProvider.notifier).loadRemittances();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Error al cargar datos del Dashboard',
          type: SnackBarType.error,
        );
      }
    }
  }

}
