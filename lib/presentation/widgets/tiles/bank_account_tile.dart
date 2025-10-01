import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yo_te_pago/business/config/constants/app_remittance_states.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/providers/bank_account_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/shared/confirm_modal_dialog.dart';


class BankAccountTile extends ConsumerWidget {

  final BankAccount account;
  final String? role;

  const BankAccountTile({
    super.key,
    required this.account,
    this.role
  });

  Future<void> _onDeleteAccount(BuildContext context, WidgetRef ref) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => ConfirmModalDialog(
        title: AppTitles.confirmation,
        content: '¿Estás seguro de que quieres eliminar la cuenta bancaria ${account.toString()} de ${account.partnerName}?',
        confirmButtonText: AppButtons.delete,
        confirmButtonColor: Colors.blueAccent,
      ),
    ) ?? false;
    if (!confirm) {
      return;
    }

    final odooService = ref.read(odooServiceProvider);
    final accountNotifier = ref.read(accountProvider.notifier);

    try {
      final bool success = await odooService.deleteBankAccount(account);
      if (!context.mounted) {
        return;
      }
      if (success) {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.accountDeletedSuccess,
          type: SnackBarType.success,
        );
        await accountNotifier.loadAccounts();
      } else {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.accountDeletedError,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showCustomSnackBar(
        context: context,
        message: 'Error al eliminar cuenta bancaria',
        type: SnackBarType.error,
      );
    }

  }

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
                              onPressed: () => _onDeleteAccount(context, ref))
                        ]
                    )
                  : null,
            )
        )
    );
  }


}
