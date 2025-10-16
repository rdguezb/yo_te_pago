import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/helpers/human_formats.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/providers/currency_provider.dart';

class CurrencyTile extends ConsumerWidget {

  final Currency currency;

  const CurrencyTile({
    super.key,
    required this.currency
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    final statusColor = currency.isActive
        ? Colors.green
        : colors.onSurface.withAlpha(153);

    return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
            padding: const EdgeInsets.all(4.0),
            child:  ListTile(
                title: Text(
                    currency.toString(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                subtitle: Text(
                    HumanFormats.toAmount(currency.rate, currency.symbol, 2),
                    style: TextStyle(
                        color: statusColor.withAlpha(200),
                        fontSize: 16.0)
                ),
                trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currency.isActive && !currency.isReference)
                        IconButton(
                            icon: Icon(Icons.currency_exchange_rounded, size: 32),
                            onPressed: () => _onUpdateRate(context, ref)
                        ),
                      IconButton(
                          icon: Icon(
                            currency.isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
                            color: statusColor,
                            size: 32
                          ),
                          onPressed: () => ref.read(currencyProvider.notifier).toggleCurrencyActive(currency.id!)
                      )
                    ]
                )
            )
        )
    );
  }

  Future<void> _onUpdateRate(BuildContext context, WidgetRef ref) async {
    final newRateController = TextEditingController();

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Actualizar Tasa'),
          content: TextField(
            controller: newRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Nueva tasa',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final newRate = double.tryParse(newRateController.text);
                if (newRate != null) {
                  ref.read(currencyProvider.notifier).updateCurrencyRate(currency.id!, newRate);
                  Navigator.of(context).pop();
                } 
              },
              child: const Text('Actualizar'),
            ),
          ],
        ));
  }
}
