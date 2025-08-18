import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/balance_provider.dart';
import 'package:yo_te_pago/presentation/widgets/reports/balance_tile.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yo_te_pago/presentation/widgets/shared/fancy_text.dart';


class ReportView extends ConsumerStatefulWidget {

  const ReportView({super.key});

  @override
  ConsumerState<ReportView> createState() => _ReportViewState();

}


class _ReportViewState extends ConsumerState<ReportView> {

  bool _dataLoadTriggered = false;

  Future<void> _loadDataOnceAuthenticated() async {
    if (_dataLoadTriggered) {
      return;
    }
    _dataLoadTriggered = true;

    try {
      await ref.read(balanceProvider.notifier).loadBalances();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Error al cargar datos del Balance',
          type: SnackBarType.error,
        );
      }
      _dataLoadTriggered = false;
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final authState = ref.read(authNotifierProvider);
      if (authState.isLoggedIn) {
        _loadDataOnceAuthenticated();
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final balancesState = ref.watch(balanceProvider);

    ref.listen<bool>(authNotifierProvider.select((auth) => auth.isLoggedIn), (prev, next) {
      if (next && !_dataLoadTriggered) {
        _loadDataOnceAuthenticated();
      }
    });
    if (!authState.isLoggedIn || balancesState.isLoading ) {
      return const Center(child: CircularProgressIndicator());
    }
    if (balancesState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'Error al cargar balances: ${balancesState.errorMessage}',
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _dataLoadTriggered = false;
                _loadDataOnceAuthenticated();
              },
              child: const Text(AppButtons.retry),
            ),
          ],
        ),
      );
    }

    final Widget body;

    if (balancesState.balances.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(24.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: Icon(
                  Icons.query_stats,
                  color: colors.primary,
                  size: 60,
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
            ),
            SliverToBoxAdapter(
              child: FancyText(
                messageText: AppNetworkMessages.errorNoBalance,
                iconData: Icons.sentiment_dissatisfied_rounded,
                color: colors.error,
              ),
            ),
          ],
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.all(24.0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: Icon(
                  Icons.query_stats,
                  color: colors.primary,
                  size: 60,
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final balance = balancesState.balances[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: BalanceTile(balance: balance),
                  );
                },
                childCount: balancesState.balances.length,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTitles.reports),
        centerTitle: true
      ),
      body: SafeArea(
        child: body
      )
    );
  }

}