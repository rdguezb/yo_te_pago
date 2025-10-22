import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yo_te_pago/business/config/constants/app_messages.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/accounts_provider.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/account_tile.dart';


class AccountViews extends ConsumerStatefulWidget {

  static const name = 'account';

  const AccountViews({super.key});

  @override
  ConsumerState<AccountViews> createState() => _AccountViewsState();

}

class _AccountViewsState extends ConsumerState<AccountViews> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(accountProvider).accounts.isEmpty) {
        ref.read(accountProvider.notifier).loadAccounts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final accountState = ref.watch(accountProvider);
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.session?.user.roleName;
    final filteredAccounts = accountState.filteredAccounts;

    ref.listen(accountProvider, (previous, next) {
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
        appBar: AppBar(
            title: const Text(AppTitles.bankAccount),
            centerTitle: true
        ),
        floatingActionButton: (userRole == ApiRole.manager)
            ? FloatingActionButton(
            heroTag: 'addAccount',
            onPressed: () => context.pushNamed(AppRoutes.account),
            tooltip: 'Asociar cuenta bancaria',
            child: const Icon(Icons.add)
        )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref.read(accountProvider.notifier).refreshAccounts(),
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

                        if (userRole != ApiRole.delivery)
                          SliverToBoxAdapter(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: TextFormField(
                                      onChanged: (query) {
                                        ref.read(accountProvider.notifier).setSearchQuery(query);
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

                        const SliverToBoxAdapter(child: SizedBox(height: 24)),

                        if (accountState.isLoading && filteredAccounts.isEmpty)
                          const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (accountState.errorMessage != null && filteredAccounts.isEmpty)
                          SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        accountState.errorMessage!,
                                        style: TextStyle(color: colors.error),
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () => ref.read(accountProvider.notifier).refreshAccounts(),
                                      child: const Text(AppButtons.retry)
                                    )
                                  ]
                                )
                              )
                          )
                        else if (filteredAccounts.isEmpty)
                          SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                  child: Text(
                                      'No se encontraron cuentas bancarias!',
                                      style: Theme.of(context).textTheme.titleMedium
                                  )
                              )
                          )
                        else
                          SliverList(
                              delegate: SliverChildBuilderDelegate(
                                      (BuildContext context, int index) {
                                    final account = filteredAccounts[index];

                                    return AccountTile(
                                      role: userRole, account: account);
                                  },
                                  childCount: filteredAccounts.length
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
