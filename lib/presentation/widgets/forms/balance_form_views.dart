import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_record_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_validation.dart';
import 'package:yo_te_pago/business/config/constants/bottom_bar_items.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/providers/currency_provider.dart';
import 'package:yo_te_pago/business/providers/delivery_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';

class BalanceFormView extends ConsumerStatefulWidget {

  static const name = 'balance-form-views';

  const BalanceFormView({
    super.key
  });

  @override
  ConsumerState<BalanceFormView> createState() => _BalanceFormViewState();

}

class _BalanceFormViewState extends ConsumerState<BalanceFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final String goBackLocation = appBottomNavigationItems['balance']!.path;
  final TextEditingController _amountController = TextEditingController();

  String? _selectedCurrencyId;
  String? _selectedDeliveryId;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(currencyProvider.notifier).loadCurrencies();
      ref.read(deliveryProvider.notifier).loadDeliveries();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();

    super.dispose();
  }

  Future<void> _updateBalance(String action) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      showCustomSnackBar(
          context: context,
          message: AppRecordMessages.formHasErrors,
          type: SnackBarType.warning);
      return;
    }

    if (_selectedCurrencyId == null || _selectedDeliveryId == null) {
      showCustomSnackBar(
          context: context,
          message: AppValidationMessages.selectionRequired,
          type: SnackBarType.warning);
      return;
    }

    if (!mounted) return;

    final odooService = ref.read(odooServiceProvider);
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    try {
      final currency = ref.read(currencyProvider).currencies.firstWhere(
              (c) => c.id.toString() == _selectedCurrencyId);
      final delivery = ref.read(deliveryProvider).deliveries.firstWhere(
              (c) => c.id.toString() == _selectedDeliveryId);

      await odooService.updateBalance(currency.id!,
          delivery.id!,
          amount,
          action);

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
    final currencyState = ref.watch(currencyProvider);
    final deliveryState = ref.watch(deliveryProvider);

    return Scaffold(
        appBar: AppBar(
            title: Text(AppTitles.balanceCreate),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.canPop() ? context.pop() : context.go(goBackLocation)
            )
        ),
        body: SafeArea(
            child: (currencyState.isLoading && currencyState.currencies.isEmpty) ||
            (deliveryState.isLoading && deliveryState.deliveries.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : _BalanceForm(
                formKey: _formKey,
                amountController: _amountController,
                onCurrencyChanged: (value) => setState(() => _selectedCurrencyId = value),
                onDeliveryChanged: (value) => setState(() => _selectedDeliveryId = value),
                selectedCurrencyId: _selectedCurrencyId,
                selectedDeliveryId: _selectedDeliveryId,
                onSave: _updateBalance)
        )
    );

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

  const _BalanceForm({
    required this.formKey,
    required this.amountController,
    required this.onSave,
    required this.onCurrencyChanged,
    required this.onDeliveryChanged,
    this.selectedCurrencyId,
    this.selectedDeliveryId
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

                CustomTextFormField(
                  label: AppFormLabels.amount,
                  controller: amountController,
                  validator: (value) => FormValidators.validateInteger(value),
                  enabled: true,
                  keyboardType: TextInputType.number,
                  isRequired: true),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonalIcon(
                        onPressed: () => onSave('credit'),
                        icon: const Icon(Icons.add),
                        label: Text(AppButtons.inCash)
                    ),
                    FilledButton.tonalIcon(
                        onPressed: () => onSave('debit'),
                        icon: const Icon(Icons.remove),
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

