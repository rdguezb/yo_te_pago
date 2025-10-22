import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/providers/users_provider.dart';

class UserTile extends ConsumerWidget {

  final User user;

  const UserTile({
    super.key,
    required this.user
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
                    user.name,
                    style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                subtitle: Text(
                    '[${user.login}] - ${user.roleName}',
                    style: TextStyle(
                        color: colors.onSurface.withAlpha(178),
                        fontSize: 16.0)
                ),
                trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: Icon(
                              Icons.mode_edit_rounded,
                              color: colors.onSurface,
                              size: 32),
                          onPressed: () => _onEdit(context, ref)
                      ),
                      IconButton(
                          icon: Icon(
                            Icons.key_rounded,
                            color: colors.onSurface,
                            size: 32),
                          onPressed: () => _changePassword(context, ref)
                      ),
                      IconButton(
                          icon: const Icon(Icons.delete_outline_sharp),
                          color: colors.error,
                          onPressed: () => _onDelete(context, ref)
                      )
                    ]
                )
            )
        )
    );
  }

  Future<void> _onEdit(BuildContext context, WidgetRef ref) async {

  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final TextEditingController passwordController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
        context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: TextField(
              controller: passwordController,
              autofocus: true,
              keyboardType: TextInputType.text,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Contraseña',
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

    if (confirmed == true && passwordController.text.trim().isNotEmpty) {
      final password = passwordController.text.trim();
      await ref.read(usersProvider.notifier).changeUserPassword(user.id!, password);
    }
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
        context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el usuario "${user.name}"? Esta acción no se puede deshacer.'),
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
      await ref.read(usersProvider.notifier).deleteUser(user.id!);
    }
  }
}
