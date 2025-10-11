import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/rates_provider.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/rate_tile.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class RatesView extends ConsumerStatefulWidget {

  static const name = 'rate';

  const RatesView({super.key});

  @override
  ConsumerState<RatesView> createState() => _RatesViewState();

}

class _RatesViewState extends ConsumerState<RatesView> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(rateProvider).rates.isEmpty) {
        ref.read(rateProvider.notifier).loadRates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final ratesState = ref.watch(rateProvider);
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.session?.role;
    final filteredRates = ratesState.filteredRates;

    ref.listen(rateProvider, (previous, next) {
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: next.errorMessage!,
          type: SnackBarType.error
        );
      }
      if (next.lastUpdateSuccess && previous?.lastUpdateSuccess == false) {
        showCustomSnackBar(
          scaffoldMessenger: ScaffoldMessenger.of(context),
          message: AppMessages.operationSuccess,
          type: SnackBarType.success
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTitles.currencyRates),
        centerTitle: true
      ),
      floatingActionButton: (userRole == ApiRole.manager)
          ? FloatingActionButton(
              heroTag: 'addRate',
              onPressed: () => context.pushNamed(AppRoutes.rate),
              tooltip: 'Agregar tasa',
              child: const Icon(Icons.add)
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(rateProvider.notifier).refreshRates(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  SliverToBoxAdapter(
                      child: Center(
                          child: Icon(
                              Icons.currency_exchange,
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
                                  ref.read(rateProvider.notifier).setSearchQuery(query);
                                },
                                decoration: InputDecoration(
                                    hintText: AppFormLabels.hintDeliverySearch,
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0)
                                )
                            )
                        )
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  if (ratesState.errorMessage != null && filteredRates.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                ratesState.errorMessage!,
                                style: TextStyle(color: colors.error),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => ref.read(rateProvider.notifier).refreshRates(),
                              child: const Text(AppButtons.retry)
                            )
                          ]
                        )
                      )
                    )
                  else if (filteredRates.isEmpty)
                    SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child: Text(
                                'No se encontraron tasas!',
                                style: Theme.of(context).textTheme.titleMedium
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
            ),
          )
      )
    );
  }

}
