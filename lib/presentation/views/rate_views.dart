import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/rate_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/rate_tile.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class RatesView extends ConsumerStatefulWidget {

  const RatesView({super.key});

  @override
  ConsumerState<RatesView> createState() => _RatesViewState();

}

class _RatesViewState extends ConsumerState<RatesView> {

  final TextEditingController _searchController = TextEditingController();

  Future<void> _loadData() async {
    try {
      await ref.read(rateProvider.notifier).loadRates();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Error al cargar datos de las monedas',
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
    final ratesState = ref.watch(rateProvider);
    final authState = ref.watch(authNotifierProvider);
    final userRole = ref.read(odooSessionNotifierProvider).session?.role;

    if (!authState.isLoggedIn || ratesState.isLoading ) {
      return const Center(child: CircularProgressIndicator());
    }

    final query = _searchController.text.toLowerCase();
    final filteredRates = ratesState.rates.where((rate) {
      return rate.partnerName!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTitles.currencyRates),
        centerTitle: true
      ),
      floatingActionButton: (userRole == ApiRole.manager)
          ? FloatingActionButton(
              heroTag: 'addRate',
              onPressed: () => context.go('/rate/create'),
              tooltip: 'Agregar tasa',
              child: const Icon(Icons.add)
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
                            Icons.currency_exchange,
                            color: colors.primary,
                            size: 60
                        )
                    )
                ),

                const SliverPadding(
                    padding: EdgeInsets.symmetric(vertical: 16.0)
                ),

                if (userRole != ApiRole.delivery)
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: TextFormField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                  hintText: AppFormLabels.hintDeliverySearch,
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

                if (ratesState.errorMessage != null && filteredRates.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              '${ratesState.errorMessage}',
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
                  if (filteredRates.isEmpty)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Text(
                                'No se encontraron tasas!',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red)
                            )
                        )
                    )
                  else
                    SliverList(
                        delegate: SliverChildBuilderDelegate(
                                (BuildContext context, int index) {
                              final rate = filteredRates[index];

                              return RateTile(
                                  role: userRole,
                                  rate: rate);
                            },
                            childCount: filteredRates.length
                        )
                    )
              ]
            )
          )
      )
    );
  }

}
