import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_record_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/app_validation.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/domain/entities/account.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/accounts_provider.dart';
import 'package:yo_te_pago/business/providers/bank_accounts_provider.dart';
import 'package:yo_te_pago/business/providers/deliveries_provider.dart';
import 'package:yo_te_pago/presentation/routes/app_router.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class BankAccountFormView extends ConsumerStatefulWidget {

  static const name = 'account';

  const BankAccountFormView({
    super.key
  });

  @override
  ConsumerState<BankAccountFormView> createState() => _BankAccountFormViewState();

}

class _BankAccountFormViewState extends ConsumerState<BankAccountFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedAccountId;
  String? _selectedDeliveryId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(bankAccountProvider).bankAccounts.isEmpty) {
        ref.read(bankAccountProvider.notifier).loadBankAccounts();
      }
      if (ref.read(deliveryProvider).deliveries.isEmpty) {
        ref.read(deliveryProvider.notifier).loadDeliveries();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bankAccountState = ref.watch(bankAccountProvider);
    final deliveryState = ref.watch(deliveryProvider);

    final goBackLocation = ref.read(appRouterProvider).namedLocation(AppRoutes.home, pathParameters: {'page': '3'});

    return Scaffold(
        appBar: AppBar(
            title: Text(AppTitles.bankAccountLink),
            centerTitle: true,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.canPop() ? context.pop() : context.go(goBackLocation)
            )
        ),
        body: SafeArea(
            child: (bankAccountState.isLoading || deliveryState.isLoading)
                ? const Center(child: CircularProgressIndicator())
                : _BankAccountForm(
                formKey: _formKey,
                onAccountChanged: (value) => setState(() => _selectedAccountId = value),
                onDeliveryChanged: (value) => setState(() => _selectedDeliveryId = value),
                selectedAccountId: _selectedAccountId,
                selectedDeliveryId: _selectedDeliveryId,
                onSave: _saveAccount
            )
        )
    );
  }

  Future<void> _saveAccount() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final goBackLocation = ref.read(appRouterProvider).namedLocation(AppRoutes.home, pathParameters: {'page': '3'});

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppRecordMessages.formHasErrors,
          type: SnackBarType.warning);
      return;
    }

    if (_selectedAccountId == null || _selectedDeliveryId == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppValidationMessages.selectionRequired,
          type: SnackBarType.warning);
      return;
    }

    try {
      final account = ref.read(bankAccountProvider).bankAccounts.firstWhereOrNull(
              (c) => c.id.toString() == _selectedAccountId);
      final delivery = ref.read(deliveryProvider).deliveries.firstWhereOrNull(
              (c) => c.id.toString() == _selectedDeliveryId);

      if (account == null || delivery == null) {
        showCustomSnackBar(
            scaffoldMessenger: scaffoldMessenger,
            message: 'La cuenta de banco o remesero seleccionado ya no son válidos.',
            type: SnackBarType.error);
        return;
      }

      final accountToSave = Account(
          id: account.id,
          name: account.name,
          bankName: account.bankName,
          partnerId: delivery.id,
          partnerName: delivery.name
      );

      await ref.read(accountProvider.notifier).linkAccount(accountToSave);

      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppRecordMessages.registerSuccess,
          type: SnackBarType.success);
      
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(goBackLocation);
      }
    } on OdooException catch (e) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: e.message,
          type: SnackBarType.error);
    } catch (e) {
      print('Error: $e');
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Ocurrió un error inesperado al asociar la cuenta bancaria.',
          type: SnackBarType.error);
    }
  }

}

class _BankAccountForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final VoidCallback onSave;
  final ValueChanged<String?> onAccountChanged;
  final ValueChanged<String?> onDeliveryChanged;
  final String? selectedAccountId;
  final String? selectedDeliveryId;

  const _BankAccountForm({
    required this.formKey,
    required this.onSave,
    required this.onAccountChanged,
    required this.onDeliveryChanged,
    this.selectedAccountId,
    this.selectedDeliveryId
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final bankAccountState = ref.watch(bankAccountProvider);
    final deliveryState = ref.watch(deliveryProvider);

     return SingleChildScrollView(
         padding: const EdgeInsets.all(24.0),
         child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                      Icons.account_balance_rounded,
                      color: colors.primary,
                      size: 80
                  ),

                  const SizedBox(height: 40),

                  _buildDeliveryDropdown(context, ref, deliveryState, onDeliveryChanged, selectedDeliveryId),

                  const SizedBox(height: 20),

                  _buildAccountDropdown(context, ref, bankAccountState, onAccountChanged, selectedAccountId),

                  const SizedBox(height: 40),

                  FilledButton.tonalIcon(
                      onPressed: onSave,
                      icon: const Icon(Icons.save),
                      label: Text(AppButtons.save)
                  )
                ]
            )
         )
    );

  }

  Widget _buildDeliveryDropdown(BuildContext context, WidgetRef ref, DeliveryState state, ValueChanged<String?> onChanged, String? selectedId) {
    if (state.errorMessage != null) {
      return Column(
          children: [
            Text(
                '${state.errorMessage!}. Por favor, intente recargar.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  ref.read(deliveryProvider.notifier).loadDeliveries();
                },
                child: const Text(AppButtons.retry)
            )
          ]
      );
    }

    if (state.deliveries.isEmpty && !state.isLoading) {
      return const Center(
        child: Text(
          'No hay remeseros disponibles.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ComboBoxPicker(
        hint: AppFormLabels.username,
        label: AppFormLabels.delivery,
        isRequired: true,
        selectedId: selectedId,
        items: state.deliveries.map((delivery) => DropdownMenuItem<String>(
            value: '${delivery.id}',
            child: Text(
                delivery.name,
                overflow: TextOverflow.ellipsis))
        ).toList(),
        validator: (value) => value == null ? AppValidationMessages.deliverySelection : null,
        onChanged: onChanged
    );
  }

  Widget _buildAccountDropdown(BuildContext context, WidgetRef ref, BankAccountState state, ValueChanged<String?> onChanged, String? selectedId) {
    if (state.errorMessage != null) {
      return Column(
          children: [
            Text(
                '${state.errorMessage!}. Por favor, intente recargar.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  ref.read(bankAccountProvider.notifier).loadBankAccounts();
                },
                child: const Text(AppButtons.retry)
            )
          ]
      );
    }

    if (state.bankAccounts.isEmpty && !state.isLoading) {
      return const Center(
        child: Text(
          'No hay cuentas bancarias sin vincular.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ComboBoxPicker(
        hint: AppFormLabels.bankAccount,
        label: AppFormLabels.accountBank,
        isRequired: true,
        selectedId: selectedId,
        items: state.bankAccounts.map((account) => DropdownMenuItem<String>(
            value: '${account.id}',
            child: Text(
                account.toString(),
                overflow: TextOverflow.ellipsis))
        ).toList(),
        validator: (value) => value == null ? AppValidationMessages.accountSelection : null,
        onChanged: onChanged
    );
  }

}
