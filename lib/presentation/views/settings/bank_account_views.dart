import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/bank_accounts_provider.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/bank_account_tile.dart';

class BankAccountViews extends ConsumerStatefulWidget {

  static const name = AppRoutes.bankAccount;

  const BankAccountViews({super.key});

  @override
  ConsumerState<BankAccountViews> createState() => _BankAccountViewsState();

}

class _BankAccountViewsState extends ConsumerState<BankAccountViews> {

  bool _isInitialLoadAttempted = false;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialLoadAttempted && ref.read(bankAccountProvider).bankAccounts.isEmpty) {
      Future.microtask(() => ref.read(bankAccountProvider.notifier).loadBankAccounts());
      _isInitialLoadAttempted = true;
    }

    final colors = Theme.of(context).colorScheme;
    final bankAccountState = ref.watch(bankAccountProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    ref.listen(bankAccountProvider, (previous, next) {
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
            title: const Text(AppTitles.bankAccount),
            centerTitle: true
        ),
        floatingActionButton: FloatingActionButton(
            heroTag: 'addBankAccount',
            onPressed: () => context.pushNamed(AppRoutes.bankAccountCreate),
            tooltip: 'Crear cuenta de banco',
            child: const Icon(Icons.add)
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
            child: RefreshIndicator(
                onRefresh: () => ref.read(bankAccountProvider.notifier).refreshBankAccounts(),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CustomScrollView(
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                          SliverToBoxAdapter(
                              child: Center(
                                  child: Icon(
                                      Icons.account_balance_rounded,
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
                                        ref.read(bankAccountProvider.notifier).setSearchQuery(query);
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

                          _buildContent(bankAccountState, colors, context)
                        ]
                    )
                )
            )

        )
    );
  }

  Widget _buildContent(BankAccountState bankAccountState, ColorScheme colors, BuildContext context) {
    final filteredBankAccount = bankAccountState.filteredBankAccounts;

    if (bankAccountState.isLoading && filteredBankAccount.isEmpty) {

      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator())
      );
    }

    if (bankAccountState.errorMessage != null && filteredBankAccount.isEmpty) {
      return SliverFillRemaining(
          child: Center(
              child: Text(
                  bankAccountState.errorMessage!,
                  style: TextStyle(color: colors.error),
                  textAlign: TextAlign.center
              )
          )
      );
    }

    if (filteredBankAccount.isEmpty) {
      return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
              child: Text(
                  'No se encontraron cuentas de bancos!',
                  style: Theme.of(context).textTheme.titleMedium
              )
          )
      );
    }

    return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final bankAccount = filteredBankAccount[index];

          return BankAccountTile(bankAccount: bankAccount);
        },
            childCount: filteredBankAccount.length
        )
    );
  }

}
