import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/app_validation.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/providers/balances_provider.dart';
import 'package:yo_te_pago/business/providers/currencies_provider.dart';
import 'package:yo_te_pago/business/providers/deliveries_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/decimal_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';

class BalanceFormView extends ConsumerStatefulWidget {

  static const name = AppRoutes.balance;

  const BalanceFormView({
    super.key
  });

  @override
  ConsumerState<BalanceFormView> createState() => _BalanceFormViewState();

}

class _BalanceFormViewState extends ConsumerState<BalanceFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCurrencyId;
  String? _selectedDeliveryId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(currencyProvider).currencies.isEmpty) {
        ref.read(currencyProvider.notifier).loadCurrencies();
      }
      if (ref.read(deliveryProvider).deliveries.isEmpty) {
        ref.read(deliveryProvider.notifier).loadDeliveries();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final balanceState = ref.watch(balanceProvider);
    final currencyState = ref.watch(currencyProvider);
    final deliveryState = ref.watch(deliveryProvider);

    ref.listen(balanceProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        showCustomSnackBar(
            scaffoldMessenger: scaffoldMessenger,
            message: next.errorMessage!,
            type: SnackBarType.error
        );
      }
      if (next.lastUpdateSuccess && previous?.lastUpdateSuccess == false) {
        showCustomSnackBar(
            scaffoldMessenger: scaffoldMessenger,
            message: AppMessages.operationSuccess,
            type: SnackBarType.success
        );
        if (context.canPop()) context.pop();
      }
    });

    return Scaffold(
        appBar: AppBar(
            title: Text(AppTitles.balanceCreate),
            centerTitle: true
        ),
        body: SafeArea(
            child: (currencyState.isLoading || deliveryState.isLoading)
            ? const Center(child: CircularProgressIndicator())
            : _BalanceForm(
                formKey: _formKey,
                amountController: _amountController,
                onCurrencyChanged: (value) => setState(() => _selectedCurrencyId = value),
                onDeliveryChanged: (value) => setState(() => _selectedDeliveryId = value),
                selectedCurrencyId: _selectedCurrencyId,
                selectedDeliveryId: _selectedDeliveryId,
                isSaving: balanceState.isLoading,
                onSave: _updateBalance)
        )
    );

  }

  Future<void> _updateBalance(String action) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.formHasErrors,
          type: SnackBarType.warning);
      return;
    }

    if (_selectedCurrencyId == null || _selectedDeliveryId == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppValidationMessages.selectionRequired,
          type: SnackBarType.warning);
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final currencyId = int.tryParse(_selectedCurrencyId!);
    final deliveryId = int.tryParse(_selectedDeliveryId!);

    if (currencyId == null || deliveryId == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'La moneda o remesero seleccionado no son válidos.',
          type: SnackBarType.error);
      return;
    }

    await ref.read(balanceProvider.notifier).updateBalance(
        currencyId,
        deliveryId,
        amount,
        action);
  }

}

class _BalanceForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final void Function(String action) onSave;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String?> onDeliveryChanged;
  final String? selectedCurrencyId;
  final String? selectedDeliveryId;
  final bool isSaving;

  const _BalanceForm({
    required this.formKey,
    required this.amountController,
    required this.onSave,
    required this.onCurrencyChanged,
    required this.onDeliveryChanged,
    this.selectedCurrencyId,
    this.selectedDeliveryId,
    this.isSaving = false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final currencyState = ref.watch(currencyProvider);
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
                    Icons.shopify_outlined,
                    color: colors.primary,
                    size: 80
                ),

                const SizedBox(height: 40),

                _buildDeliveryDropdown(context, ref, deliveryState, onDeliveryChanged, selectedDeliveryId),

                const SizedBox(height: 20),

                _buildCurrencyDropdown(context, ref, currencyState, onCurrencyChanged, selectedCurrencyId),

                const SizedBox(height: 20),

                DecimalTextFormField(
                    label: AppFormLabels.amount,
                    controller: amountController,
                    validator: (value) => FormValidators.validateDouble(value),
                    enabled: true,
                    isRequired: true),

                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonalIcon(
                        onPressed: isSaving ? null : () => onSave('credit'),
                        icon: isSaving ? const SizedBox.shrink() : const Icon(Icons.add),
                        label: Text(AppButtons.inCash)
                    ),

                    const SizedBox(width: 20),

                    FilledButton.tonalIcon(
                        onPressed: isSaving ? null : () => onSave('debit'),
                        icon: isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.remove),
                        label: Text(AppButtons.outCash)
                    ),
                  ],
                )
              ]
          )
        )
    );
  }

  Widget _buildDeliveryDropdown (BuildContext context, WidgetRef ref, DeliveryState state, ValueChanged<String?> onChanged, String? selectedId) {
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

  Widget _buildCurrencyDropdown(BuildContext context, WidgetRef ref, CurrencyState state, ValueChanged<String?> onChanged, String? selectedId) {
    assert(state.currencies.isNotEmpty || state.errorMessage != null || state.isLoading);

    if (state.errorMessage != null && state.currencies.isEmpty) {
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
                  ref.read(currencyProvider.notifier).loadCurrencies();
                },
                child: const Text(AppButtons.retry)
            )
          ]
      );
    }
    return ComboBoxPicker(
        hint: AppFormLabels.paymentCurrency,
        label: AppFormLabels.currency,
        isRequired: true,
        selectedId: selectedId,
        items: state.currencies.map((currency) => DropdownMenuItem<String>(
            value: '${currency.id}',
            child: Text(currency.toString(), overflow: TextOverflow.ellipsis)))
            .toList(),
        validator: (value) => value == null ? AppValidationMessages.currencySelection : null,
        onChanged: onChanged
    );  }

}

