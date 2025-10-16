
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/banks_provider.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/bank_tile.dart';


class BankViews extends ConsumerStatefulWidget {

  static const name = AppRoutes.banks;

  const BankViews({super.key});

  @override
  ConsumerState<BankViews> createState() => _BankViewsState();

}

class _BankViewsState extends ConsumerState<BankViews> {

  bool _isInitialLoadAttempted = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialLoadAttempted && ref.read(bankProvider).banks.isEmpty) {
      Future.microtask(() => ref.read(bankProvider.notifier).loadBanks());
      _isInitialLoadAttempted = true;
    }

    final colors = Theme.of(context).colorScheme;
    final bankState = ref.watch(bankProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    ref.listen(bankProvider, (previous, next) {
      if (previous != null && previous.errorMessage == null && next.errorMessage != null) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: next.errorMessage!,
          type: SnackBarType.error
        );
      }
      if (previous != null && !previous.lastUpdateSuccess && next.lastUpdateSuccess) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.operationSuccess,
          type: SnackBarType.success
        );
      }
    });

    return Scaffold(
        appBar: AppBar(
            title: const Text(AppTitles.bank),
            centerTitle: true
        ),
        floatingActionButton: FloatingActionButton(
            heroTag: 'addBank',
            onPressed: () => context.pushNamed(AppRoutes.banksCreate),
            tooltip: 'Crear banco',
            child: const Icon(Icons.add)
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: () => ref.read(bankProvider.notifier).refreshBanks(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),

                        SliverToBoxAdapter(
                            child: Center(
                                child: Icon(
                                    Icons.domain_outlined,
                                    color: colors.primary,
                                    size: 60
                                )
                            )
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 24)),

                        SliverToBoxAdapter(
                            child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: TextFormField(
                                    onChanged: (query) {
                                      ref.read(bankProvider.notifier).setSearchQuery(query);
                                    },
                                    decoration: InputDecoration(
                                        hintText: AppFormLabels.hintNameSearch,
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0)
                                    )
                                )
                            )
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 24)),

                        _buildContent(bankState, colors, context)
                      ]
                  )
                )
            )

        )
    );
  }

  Widget _buildContent(BankState bankState, ColorScheme colors, BuildContext context) {
    final filteredBanks = bankState.filteredBanks;

    if (bankState.isLoading && filteredBanks.isEmpty) {

      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator())
      );
    }

    if (bankState.errorMessage != null && filteredBanks.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            bankState.errorMessage!,
            style: TextStyle(color: colors.error),
            textAlign: TextAlign.center
          )
        )
      );
    }

    if (filteredBanks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No se encontraron bancos!',
            style: Theme.of(context).textTheme.titleMedium
          )
        )
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final bank = filteredBanks[index];

          return BankTile(bank: bank);
        },
        childCount: filteredBanks.length
      )
    );
  }
}
