import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/providers/bank_accounts_provider.dart';


class BankAccountTile extends ConsumerStatefulWidget {

  final BankAccount bankAccount;

  const BankAccountTile({
    super.key,
    required this.bankAccount
  });

  @override
  ConsumerState<BankAccountTile> createState() => _BankAccountTileState();

}

class _BankAccountTileState extends ConsumerState<BankAccountTile> {

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
            padding: const EdgeInsets.all(4.0),
            child:  ListTile(
                title: Text(
                    widget.bankAccount.name,
                    style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1
                ),
                subtitle: Text(
                    widget.bankAccount.bankName,
                    style: TextStyle(
                        color: colors.onSurface.withAlpha(178),
                        fontSize: 16.0)
                ),
                trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.mode_edit_rounded),
                          onPressed: () => context.pushNamed(
                              AppRoutes.bankAccountCreate, extra: widget.bankAccount)
                      ),
                      IconButton(
                          icon: const Icon(Icons.delete_outline_sharp),
                          color: colors.error,
                          onPressed: _onDelete
                      )
                    ]
                )
            )
        )
    );
  }

  Future<void> _onDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context, builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar la cuenta "${widget.bankAccount.name}"? Esta acción no se puede deshacer.'),
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
      }
    );

    if (confirmed == true && mounted) {
      await ref.read(bankAccountProvider.notifier).deleteBankAccount(widget.bankAccount.id!);
    }
  }
}