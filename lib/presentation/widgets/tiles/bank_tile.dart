import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';

import 'package:yo_te_pago/business/domain/entities/bank.dart';
import 'package:yo_te_pago/business/providers/banks_provider.dart';

class BankTile extends ConsumerWidget {

  final Bank bank;

  const BankTile({
    super.key,
    required this.bank
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
                  bank.name,
                  style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.mode_edit_rounded),
                        onPressed: () => context.pushNamed(AppRoutes.banksCreate, extra: bank)
                    )
                  ]
              )
            )
        )
    );
  }

}