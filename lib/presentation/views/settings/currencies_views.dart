import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/currency_provider.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/currency_tile.dart';

class CurrenciesView extends ConsumerStatefulWidget {

  static const name = AppRoutes.currency;

  const CurrenciesView({super.key});

  @override
  ConsumerState<CurrenciesView> createState() => _CurrenciesViewState();

}

class _CurrenciesViewState extends ConsumerState<CurrenciesView> {

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(currencyProvider).currencies.isEmpty) {
        ref.read(currencyProvider.notifier).loadNextPage();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        ref.read(currencyProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currencyState = ref.watch(currencyProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    ref.listen(currencyProvider, (previous, next) {
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
            title: const Text(AppTitles.currencies),
            centerTitle: true
        ),
        body: SafeArea(
            child: (currencyState.isLoading && currencyState.currencies.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => ref.read(currencyProvider.notifier).refresh(),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                          SliverToBoxAdapter(
                              child: Center(
                                  child: Icon(
                                      Icons.monetization_on_outlined,
                                      color: colors.primary,
                                      size: 60
                                  )
                              )
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                          SliverToBoxAdapter(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: TextFormField(
                                      onChanged: (query) {
                                        ref.read(currencyProvider.notifier).setSearchQuery(query);
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

                          _buildContent(currencyState, colors, context)
                        ]
                    )
                )
            )
        )
    );
  }

  Widget _buildContent(CurrencyState currencyState, ColorScheme colors, BuildContext context) {
    final filteredCurrencies = currencyState.filteredCurrencies;

    if (currencyState.isLoading && filteredCurrencies.isEmpty) {

      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator())
      );
    }

    if (currencyState.errorMessage != null && filteredCurrencies.isEmpty) {
      return SliverFillRemaining(
          child: Center(
              child: Text(
                  currencyState.errorMessage!,
                  style: TextStyle(color: colors.error),
                  textAlign: TextAlign.center
              )
          )
      );
    }

    if (filteredCurrencies.isEmpty) {
      return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
              child: Text(
                  'No se encontraron monedas!',
                  style: Theme.of(context).textTheme.titleMedium
              )
          )
      );
    }

    return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final currency = filteredCurrencies[index];

          return CurrencyTile(currency: currency);
        },
        childCount: filteredCurrencies.length
        )
    );
  }
}