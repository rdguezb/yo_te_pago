import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/remittances_provider.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/remittance_tile.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/shared/app_bar_widget.dart';


class DashboardView extends ConsumerStatefulWidget {

  static const name = AppRoutes.dashboard;

  static String routeName(int page) => '/home/$page';
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => DashboardViewState();

}


class DashboardViewState extends ConsumerState<DashboardView> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(remittanceProvider).remittances.isEmpty) {
        ref.read(remittanceProvider.notifier).loadRemittances();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authState = ref.watch(authNotifierProvider);
    final remittancesState = ref.watch(remittanceProvider);
    final userRole = authState.session?.role;
    final filteredRemittances = remittancesState.filteredRemittances;

    ref.listen(remittanceProvider, (previous, next) {
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
          message: AppMessages.operationSuccess,
          type: SnackBarType.success
        );
      }
    });

    return Scaffold(
        floatingActionButton: userRole == ApiRole.delivery
            ? FloatingActionButton(
            heroTag: 'addRemittance',
            onPressed: () => context.pushNamed(AppRoutes.remittance),
            tooltip: 'Remesar',
            child: const Icon(Icons.add))
        : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: RefreshIndicator(
          onRefresh: () => ref.read(remittanceProvider.notifier).refreshRemittances(),
          child: CustomScrollView(
            slivers: [

              SliverAppBar(
                floating: true,
                pinned: false,
                expandedHeight: 100.0,
                flexibleSpace: FlexibleSpaceBar(
                  background: const CustomAppBar()
                )
              ),

              SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextFormField(
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

              if (remittancesState.isLoading && filteredRemittances.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (remittancesState.errorMessage != null && filteredRemittances.isEmpty)
                SliverFillRemaining(
                  child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            remittancesState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                              onPressed: () => ref.read(remittanceProvider.notifier).refreshRemittances(),
                              child: const Text(AppButtons.retry)
                          )
                        ],
                      )
                  ),
                )
              else if (filteredRemittances.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No se encontraron remesas!',
                      style: Theme.of(context).textTheme.titleMedium
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
          ),
        )
    );
  }

}
