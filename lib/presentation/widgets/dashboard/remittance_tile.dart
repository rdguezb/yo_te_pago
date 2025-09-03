import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_remittance_states.dart';
import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/human_formats.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/providers/remittance_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/shared/confirm_modal_dialog.dart';


class RemittanceTile extends ConsumerWidget {

  final Remittance remittance;
  final Currency currency;
  final BankAccount account;
  final String? role;

  const RemittanceTile({
    required this.remittance,
    required this.account,
    required this.currency,
    this.role
  });

  Color _getTileColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (remittance.isPaid) {
      return Colors.green;
    } else if (remittance.isConfirmed) {
      return Colors.blue;
    } else if (remittance.isCanceled) {
      return Colors.black45;
    } else {
      return colors.onSurface;
    }
  }

  Future<void> _onPay(BuildContext context, WidgetRef ref) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => ConfirmModalDialog(
        title: AppTitles.confirmation,
        content: '¿Estás seguro de que quieres cambiar a pagada la remesa de ${remittance.customer}?',
        confirmButtonText: AppButtons.confirm,
        confirmButtonColor: Colors.blueAccent,
      ),
    ) ?? false;
    if (!context.mounted) {
      return;
    }
    if (!confirm) {
      return;
    }

    final odooService = ref.read(odooServiceProvider);
    final remittanceNotifier = ref.read(remittanceProvider.notifier);

    try {
      final bool success = await odooService.payRemittance(remittance);
      if (!context.mounted) {
        return;
      }

      if (success) {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.remittancePaidSuccess,
          type: SnackBarType.success,
        );
        await remittanceNotifier.loadRemittances();
      } else {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.remittancePaidError,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showCustomSnackBar(
        context: context,
        message: 'Error al marcar como pagada',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => ConfirmModalDialog(
        title: AppTitles.confirmation,
        content: '¿Estás seguro de que quieres eliminar la remesa de ${remittance.customer}?',
        confirmButtonText: AppButtons.delete,
        confirmButtonColor: Colors.blueAccent,
      ),
    ) ?? false;
    if (!confirm) {
      return;
    }

    final odooService = ref.read(odooServiceProvider);
    final remittanceNotifier = ref.read(remittanceProvider.notifier);

    try {
      final bool success = await odooService.deleteRemittance(remittance);
      if (!context.mounted) {
        return;
      }
      if (success) {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.remittanceDeletedSuccess,
          type: SnackBarType.success,
        );
        await remittanceNotifier.loadRemittances();
      } else {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.remittanceDeletedError,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showCustomSnackBar(
        context: context,
        message: 'Error al eliminar remesa',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _onConfirm(BuildContext context, WidgetRef ref) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => ConfirmModalDialog(
        title: AppTitles.confirmation,
        content: '¿Estás seguro de que quieres cambiar a confirmada la remesa de ${remittance.customer}?',
        confirmButtonText: AppButtons.confirm,
        confirmButtonColor: Colors.blueAccent,
      ),
    ) ?? false;
    if (!context.mounted) {
      return;
    }
    if (!confirm) {
      return;
    }

    final odooService = ref.read(odooServiceProvider);
    final remittanceNotifier = ref.read(remittanceProvider.notifier);

    try {
      final bool success = await odooService.confirmRemittance(remittance);
      if (!context.mounted) {
        return;
      }

      if (success) {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.remittanceConfirmSuccess,
          type: SnackBarType.success,
        );
        await remittanceNotifier.loadRemittances();
      } else {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.remittanceConfirmError,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showCustomSnackBar(
        context: context,
        message: 'Error al marcar como confirmada',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color textColor = _getTileColor(context);
    final colors = Theme.of(context).colorScheme;
    final userRole = role ?? '';
    final currencyRow = Row(
      children: [
        Text(
          '${remittance.amount} | ${currency.toStr(remittance.rate)} | ${remittance.createdAtToStr}',
          style: TextStyle(color: textColor.withAlpha(178)),
        ),
        const Spacer(),
        Text(
          HumanFormats.toAmount(remittance.rate * remittance.amount, currency.symbol),
          style: TextStyle(
              color: textColor.withAlpha(178),
              fontSize: 16.0,
              fontWeight: FontWeight.bold),
        )
      ],
    );
    final bankAccountRow = Row(
      children: [
        Expanded(
          child: Text(
            account.toString(),
            style: TextStyle(
              color: textColor.withAlpha(178),
              fontSize: 16.0,
              fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(
                            remittance.customer,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if ((remittance.isWaiting || remittance.isCanceled) && (userRole == ApiRole.delivery || userRole == ApiRole.manager))
                          IconButton(
                              icon: const Icon(Icons.delete_outline_sharp),
                              color: colors.error,
                              onPressed: () => _onDelete(context, ref)),
                        if (remittance.isWaiting && userRole == ApiRole.delivery)
                          IconButton(
                              icon: const Icon(Icons.mode_edit_rounded),
                              color: textColor,
                              onPressed: () => context.go('/remittance/edit/${remittance.id}')),
                        if (remittance.isConfirmed &&  userRole == ApiRole.delivery)
                          IconButton(
                              iconSize: 40.0,
                              icon: const Icon(Icons.check_rounded),
                              color: colors.primary,
                              onPressed: () => _onPay(context, ref)),
                        if (remittance.isWaiting && userRole == ApiRole.user)
                          IconButton(
                              iconSize: 40.0,
                              icon: const Icon(Icons.thumb_up_alt_rounded),
                              color: colors.primary,
                              onPressed: () => _onConfirm(context, ref)),
                      ]
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bankAccountRow,
                        currencyRow
                      ]
                    )
                  )
                )
              ],
            ),
        )
    );
  }

}