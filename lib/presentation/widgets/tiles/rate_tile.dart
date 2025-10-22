import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/providers/rates_provider.dart';


class RateTile extends ConsumerWidget {

  final Rate rate;
  final String? role;

  const RateTile({
    super.key,
    required this.rate,
    this.role
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
            padding: const EdgeInsets.all(4.0),
            child:  ListTile(
              title: Text(
                  rate.toString(),
                  style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              subtitle: _getSubtitle(colors.onSurface.withAlpha(178)),
              trailing: (role == ApiRole.manager)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.mode_edit_rounded),
                            onPressed: () => _onChangeRate(context, ref)
                        ),
                        IconButton(
                            icon: const Icon(Icons.delete_outline_sharp),
                            color: colors.error,
                            onPressed: () => _onDeleteRate(context, ref)
                        )
                      ]
                    )
                  : null,
            )
        )
    );
  }

  Widget _getSubtitle(Color? color) {

    return (role == ApiRole.delivery)
        ? Text(
            '${rate.rate}',
            style: TextStyle(
                color: color,
                fontSize: 16.0,
                fontWeight: FontWeight.bold)
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  rate.partnerName!,
                  style: TextStyle(
                      color: color,
                      fontSize: 16.0)
              ),
              const Spacer(),
              Text(
                  '${rate.rate}',
                  style: TextStyle(
                      color: color,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold)
              )
            ]
          );
  }

  Future<void> _onChangeRate(BuildContext context, WidgetRef ref) async {
    final TextEditingController rateController = TextEditingController(text: '${rate.rate}');

    final bool? confirmed = await showDialog<bool>(
        context: context, builder: (BuildContext dialogContext) {
        return AlertDialog(
            title: const Text('Cambiar Valor de la Tasa'),
            content: TextField(
                controller: rateController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: 'Ej. 10.50',
                    labelText: 'Tasa',
                    border: OutlineInputBorder()
                ),
                onSubmitted: (value) {
                  Navigator.of(context).pop(value);
                }
            ),
            actions: <Widget>[
              TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  }
              ),
              FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Aceptar'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  }
              )
            ]
        );
      }
    );

    if (confirmed == true && rateController.text.trim().isNotEmpty) {
      final value = double.tryParse(rateController.text.trim());
      if (value != null || value! > 0) {
        final rateToUpdate = rate.copyWith(rate: value);
        await ref.read(rateProvider.notifier).changeRate(rateToUpdate);
      }
    }
  }

  Future<void> _onDeleteRate(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar la tasa para "${rate.toString()}" de "${rate.partnerName}"? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                }
            ),
            FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Eliminar'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                }
            )
          ]
      );
    });

    if (confirmed == true) {
      await ref.read(rateProvider.notifier).deleteRate(rate.id!);
    }
  }

}
