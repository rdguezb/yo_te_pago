import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/domain/entities/account.dart';
import 'package:yo_te_pago/business/providers/accounts_provider.dart';


class AccountTile extends ConsumerWidget {

  final Account account;
  final String? role;

  const AccountTile({
    super.key,
    required this.account,
    this.role
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
            padding: const EdgeInsets.all(4.0),
            child:  ListTile(
              title: Text(
                  account.toString(),
                  style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              subtitle: (role == ApiRole.manager)
                ? Text(
                  account.partnerName!,
                  style: TextStyle(
                      color: colors.onSurface.withAlpha(178),
                      fontSize: 16.0))
                : null,
              trailing: (role == ApiRole.manager)
                  ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.delete_outline_sharp),
                              color: colors.error,
                              onPressed: () => _onUnlinkAccount(context, ref))
                        ]
                    )
                  : null,
            )
        )
    );
  }

  Future<void> _onUnlinkAccount(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar la cuenta "${account.name}" de "${account.partnerName}"? Esta acción no se puede deshacer.'),
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
      await ref.read(accountProvider.notifier).deleteAccount(account);
    }
  }

}
