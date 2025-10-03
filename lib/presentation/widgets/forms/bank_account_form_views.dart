import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_record_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_validation.dart';
import 'package:yo_te_pago/business/config/constants/bottom_bar_items.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/bank_account_provider.dart';
import 'package:yo_te_pago/business/providers/delivery_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class BankAccountFormView extends ConsumerStatefulWidget {

  static const name = 'bank-account-form-views';

  const BankAccountFormView({
    super.key
  });

  @override
  ConsumerState<BankAccountFormView> createState() => _BankAccountFormViewState();

}

class _BankAccountFormViewState extends ConsumerState<BankAccountFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final String goBackLocation = appBottomNavigationItems['bank']!.path;

  String? _selectedAccountId;
  String? _selectedDeliveryId;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(accountProvider.notifier).loadAllowedAccounts() ;
      ref.read(deliveryProvider.notifier).loadDeliveries();
    });
  }

  Future<void> _saveAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      showCustomSnackBar(
          context: context,
          message: AppRecordMessages.formHasErrors,
          type: SnackBarType.warning);
      return;
    }

    if (_selectedAccountId == null || _selectedDeliveryId == null) {
      showCustomSnackBar(
          context: context,
          message: AppValidationMessages.selectionRequired,
          type: SnackBarType.warning);
      return;
    }

    if (!mounted) return;

    final odooService = ref.read(odooServiceProvider);
    try {
      final accountId = ref.read(accountProvider).allowedAccounts.firstWhere(
              (c) => c.id.toString() == _selectedAccountId);
      final delivery = ref.read(deliveryProvider).deliveries.firstWhere(
              (c) => c.id.toString() == _selectedDeliveryId);

      final account = accountId.copyWith(
          partnerId: delivery.id,
          partnerName: delivery.name
      );

      await odooService.linkBankAccount(account);

      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: AppRecordMessages.registerSuccess,
        type: SnackBarType.success,
      );

      context.go(goBackLocation);
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
          context: context,
          message: e.toString(),
          type: SnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final deliveryState = ref.watch(deliveryProvider);

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
            child: (accountState.isLoading && accountState.allowedAccounts.isEmpty) ||
                (deliveryState.isLoading && deliveryState.deliveries.isEmpty)
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
    final accountState = ref.watch(accountProvider);
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

                  _buildAccountDropdown(context, ref, accountState, onAccountChanged, selectedAccountId),

                  const SizedBox(height: 20),

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
    assert(state.deliveries.isNotEmpty || state.errorMessage != null || state.isLoading);

    if (state.errorMessage != null && state.deliveries.isEmpty) {
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
    assert(state.allowedAccounts.isNotEmpty || state.errorMessage != null || state.isLoading);

    if (state.errorMessage != null && state.allowedAccounts.isEmpty) {
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
                  ref.read(accountProvider.notifier).loadAllowedAccounts();
                },
                child: const Text(AppButtons.retry)
            )
          ]
      );
    }

    return ComboBoxPicker(
        hint: AppFormLabels.bankAccount,
        label: AppFormLabels.accountBank,
        isRequired: true,
        selectedId: selectedId,
        items: state.allowedAccounts.map((account) => DropdownMenuItem<String>(
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