import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/providers/remittances_provider.dart';
import 'package:yo_te_pago/presentation/widgets/shared/confirm_modal_dialog.dart';


class RemittanceTile extends ConsumerWidget {

  final Remittance remittance;
  final String? role;

  const RemittanceTile({
    super.key,
    required this.remittance,
    this.role
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color textColor = _getTileColor(context);
    final colors = Theme.of(context).colorScheme;
    final userRole = role ?? '';

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ListTile(
              title: Text(
                  remittance.customer,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold)),
              subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getBankAccountRow(textColor.withAlpha(178)),
                    _getCurrencyRow(textColor.withAlpha(178))
                  ]
              ),
              trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildActions(context, ref, colors, userRole, textColor)
              ),
            )
        )
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref, ColorScheme colors, String userRole, Color textColor) {
    final actions = <Widget>[];

    // Acción: EDITAR
    if (remittance.isWaiting && userRole == ApiRole.delivery) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.mode_edit_rounded),
          color: textColor,
          onPressed: () => context.pushNamed(AppRoutes.remittance, extra: remittance)
        )
      );
    }

    // Acción: ELIMINAR
    if ((remittance.isWaiting || remittance.isCanceled) && (userRole == ApiRole.delivery || userRole == ApiRole.manager)) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.delete_outline_sharp),
          color: colors.error,
          onPressed: () => _onDelete(context, ref)
        )
      );
    }

    // Acción: PAGAR (Check)
    if (remittance.isConfirmed && userRole == ApiRole.delivery) {
      actions.add(
        IconButton(
          iconSize: 40.0,
          icon: const Icon(Icons.check_rounded),
          color: colors.primary,
          onPressed: () => _onPay(context, ref)
        )
      );
    }

    // Acción: CONFIRMAR (Pulgar arriba)
    if (remittance.isWaiting && userRole == ApiRole.user) {
      actions.add(
        IconButton(
          iconSize: 40.0,
          icon: const Icon(Icons.thumb_up_alt_rounded),
          color: colors.primary,
          onPressed: () => _onConfirm(context, ref)
        )
      );
    }

    return actions;
  }

  Future<void> _showConfirmationDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String content,
    required String confirmButtonText,
    required Future<void> Function() onConfirm,
    Color confirmButtonColor = Colors.blueAccent
  }) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => ConfirmModalDialog(
        title: title,
        content: content,
        confirmButtonText: confirmButtonText,
        confirmButtonColor: confirmButtonColor
      ),
    ) ?? false;

    if (!confirm) return;

    await onConfirm();
  }

  Color _getTileColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (remittance.isPaid) return Colors.green;
    if (remittance.isConfirmed) return Colors.blue;
    if (remittance.isCanceled) return Colors.black45;
    return colors.onSurface;
  }

  Widget _getCurrencyRow(Color? color) {

    return Row(
        children: [
          Text(
              remittance.currencyInfo(),
              style: TextStyle(color: color)
          ),
          const Spacer(),
          Text(
              remittance.totalToString(),
              style: TextStyle(
                  color: color,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold)
          )
        ]
    );
  }

  Widget _getBankAccountRow(Color? color) {

    return Row(
        children: [
          Expanded(
              child: Text(
                  remittance.bankAccountInfo(),
                  style: TextStyle(
                      color: color,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis
              )
          )
        ]
    );
  }

  Future<void> _onPay(BuildContext context, WidgetRef ref) async {
    await _showConfirmationDialog(
      context: context,
      ref: ref,
      title: AppTitles.confirmation,
      content: '¿Estás seguro de que quieres cambiar a pagada la remesa de ${remittance.customer}?',
      confirmButtonText: AppButtons.confirm,
      onConfirm: () => ref.read(remittanceProvider.notifier).payRemittance(remittance.id!)
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    await _showConfirmationDialog(
      context: context,
      ref: ref,
      title: AppTitles.confirmation,
      content: '¿Estás seguro de que quieres eliminar la remesa de ${remittance.customer}?',
      confirmButtonText: AppButtons.delete,
      onConfirm: () => ref.read(remittanceProvider.notifier).deleteRemittance(remittance.id!)
    );
  }

  Future<void> _onConfirm(BuildContext context, WidgetRef ref) async {
    await _showConfirmationDialog(
      context: context,
      ref: ref,
      title: AppTitles.confirmation,
      content: '¿Estás seguro de que quieres cambiar a confirmada la remesa de ${remittance.customer}?',
      confirmButtonText: AppButtons.confirm,
      onConfirm: () => ref.read(remittanceProvider.notifier).confirmRemittance(remittance.id!)
    );
  }
  
}
