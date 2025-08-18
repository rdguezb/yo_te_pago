import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/presentation/widgets/shared/fancy_text.dart';


class CurrencyVerticalListView extends StatefulWidget {

  final List<Currency> currencies;
  final VoidCallback? loadNextPage;

  const CurrencyVerticalListView({
    super.key,
    required this.currencies,
    this.loadNextPage});

  @override
  State<CurrencyVerticalListView> createState() => _CurrencyVerticalListViewState();

}

class _CurrencyVerticalListViewState extends State<CurrencyVerticalListView> {

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      if (widget.loadNextPage == null) {
        return;
      }
      if ((scrollController.position.pixels + 200) >= scrollController.position.maxScrollExtent) {
        widget.loadNextPage!();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 250,
      child: Column(
        children: [
          Center(
            child: Text(
              AppTitles.currencyRates,
              style: style.bodyLarge,
            ),
          ),
          Expanded(
              child: widget.currencies.isEmpty
                  ? FancyText(
                  messageText: AppNetworkMessages.errorNoRates,
                  iconData: Icons.sentiment_dissatisfied_rounded,
                  color: colors.error)
                  : ListView.builder(
                controller: scrollController,
                itemCount: widget.currencies.length,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _CurrencyTile(currency: widget.currencies[index]);
                },
              ))
        ],
      ),
    );
  }

}

class _CurrencyTile extends StatelessWidget {

  final Currency currency;

  const _CurrencyTile({required this.currency});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child:  Row(
            children: [
              Flexible(
                  fit: FlexFit.loose,
                  child: ListTile(
                      title: Text(
                          '[${currency.name}]   ${currency.fullName}',
                          style: textTheme.titleMedium?.copyWith(color: colors.onSurface),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      subtitle: Text('${currency.rate}')
                  )
              )
            ]
          )
        )
    );
  }

}
