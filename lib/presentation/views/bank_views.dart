import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/account_provider.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/bank_account_tile.dart';


class BankViews extends ConsumerStatefulWidget {

  const BankViews({super.key});

  @override
  ConsumerState<BankViews> createState() => _BankViewsState();

}

class _BankViewsState extends ConsumerState<BankViews> {

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
    final accountState = ref.watch(accountProvider);
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.session?.role;

    if (!authState.isLoggedIn || accountState.isLoading ) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredAccounts = accountState.filteredAccounts;

    return Scaffold(
        appBar: AppBar(
            title: const Text(AppTitles.bankAccount),
            centerTitle: true
        ),
        floatingActionButton: (userRole == ApiRole.manager)
            ? FloatingActionButton(
            heroTag: 'addAccount',
            onPressed: () => context.go('/account/link'),
            tooltip: 'Asociar cuenta bancaria',
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
                                  Icons.account_balance_rounded,
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

                      const SliverPadding(
                          padding: EdgeInsets.symmetric(vertical: 16.0)
                      ),

                      if (accountState.errorMessage != null && filteredAccounts.isEmpty)
                        SliverToBoxAdapter(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                      accountState.errorMessage.toString(),
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
                        if (filteredAccounts.isEmpty)
                          SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                  child: Text(
                                      'No se encontraron cuentas bancarias!',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red)
                                  )
                              )
                          )
                        else
                          SliverList(
                              delegate: SliverChildBuilderDelegate(
                                      (BuildContext context, int index) {
                                    final account = filteredAccounts[index];

                                    return BankAccountTile(
                                      role: userRole,
                                      account: account);
                                  },
                                  childCount: filteredAccounts.length
                              )
                          )
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
      await ref.read(accountProvider.notifier).loadAccounts();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Error al cargar datos de las cuentas bancarias',
          type: SnackBarType.error,
        );
      }
    }
  }

}
