import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/user.dart';

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
                    '[${user.login}] - ${user.role}',
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

  Future<void> _onEdit(BuildContext context, WidgetRef ref) async {}

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {}

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {}
}
