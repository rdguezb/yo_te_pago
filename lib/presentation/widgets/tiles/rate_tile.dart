import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:yo_te_pago/business/config/constants/app_remittance_states.dart';
import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/providers/rate_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/shared/confirm_modal_dialog.dart';


class RateTile extends ConsumerWidget {

  final Rate rate;
  final String? role;

  const RateTile({
    super.key,
    required this.rate,
    this.role
  });

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

  Future<String?> showInputDialog(BuildContext context, {
    required String title,
    String? hintText,
    String? initialValue,
  }) {
    final TextEditingController controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hintText),
            onSubmitted: (value) {
              Navigator.of(context).pop(value);
            }
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              }
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              }
            )
          ]
        );
      }
    );
  }

  Future<void> _onChangeRate(BuildContext context, WidgetRef ref) async {
    final String? result = await showInputDialog(
      context,
      title: 'Introduzca nuevo valor',
      hintText: 'Ej. 10.50',
      initialValue: '${rate.rate}',
    );
    if (!context.mounted) {
      return;
    }
    if (result == null || result.isEmpty) {
      return;
    }
    final value = double.tryParse(result) ?? 0.0;
    if (value == 0) {
      return;
    }

    final odooService = ref.read(odooServiceProvider);
    final rateNotifier = ref.read(rateProvider.notifier);

    try {
      Rate newRate = rate.copyWith(rate: value);
      final bool success = await odooService.changeRate(newRate);
      if (!context.mounted) {
        return;
      }

      if (success) {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.rateChanged,
          type: SnackBarType.success,
        );
        await rateNotifier.loadRates();
      } else {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.rateChangedFail,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showCustomSnackBar(
        context: context,
        message: 'Error al cambiar la tasa',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _onDeleteRate(BuildContext context, WidgetRef ref) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => ConfirmModalDialog(
        title: AppTitles.confirmation,
        content: '¿Estás seguro de que quieres eliminar la tasa para ${rate.toString()} de ${rate.partnerName}?',
        confirmButtonText: AppButtons.delete,
        confirmButtonColor: Colors.blueAccent,
      ),
    ) ?? false;
    if (!confirm) {
      return;
    }

    final odooService = ref.read(odooServiceProvider);
    final rateNotifier = ref.read(rateProvider.notifier);

    try {
      final bool success = await odooService.deleteRate(rate);
      if (!context.mounted) {
        return;
      }
      if (success) {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.rateDeletedSuccess,
          type: SnackBarType.success,
        );
        await rateNotifier.loadRates();
      } else {
        showCustomSnackBar(
          context: context,
          message: AppRemittanceMessages.rateDeletedError,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      showCustomSnackBar(
        context: context,
        message: 'Error al eliminar tasa',
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

}
