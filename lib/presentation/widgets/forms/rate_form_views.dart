import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/app_validation.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/providers/company_currencies_provider.dart';
import 'package:yo_te_pago/business/providers/deliveries_provider.dart';
import 'package:yo_te_pago/business/providers/rates_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/decimal_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class RateFormView extends ConsumerStatefulWidget {

  static const name = AppRoutes.rate;

  const RateFormView({
    super.key,
  });

  @override
  ConsumerState<RateFormView> createState() => _RateFormViewState();

}

class _RateFormViewState extends ConsumerState<RateFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _rateController = TextEditingController();
  String? _selectedCurrencyId;
  String? _selectedDeliveryId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(companyCurrencyProvider).currencies.isEmpty) {
        ref.read(companyCurrencyProvider.notifier).loadCurrencies();
      }
      if (ref.read(deliveryProvider).deliveries.isEmpty) {
        ref.read(deliveryProvider.notifier).loadDeliveries();
      }
    });
  }

  @override
  void dispose() {
    _rateController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final currencyState = ref.watch(companyCurrencyProvider);
    final deliveryState = ref.watch(deliveryProvider);
    final rateState = ref.watch(rateProvider);

    ref.listen(rateProvider, (previous, next) {
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
            title: Text(AppTitles.rateCreate),
            centerTitle: true
        ),
        body: SafeArea(
            child: (currencyState.isLoading || deliveryState.isLoading)
                ? const Center(child: CircularProgressIndicator())
                : _RateForm(
                    formKey: _formKey,
                    rateController: _rateController,
                    onCurrencyChanged: (value) => setState(() => _selectedCurrencyId = value),
                    onDeliveryChanged: (value) => setState(() => _selectedDeliveryId = value),
                    selectedCurrencyId: _selectedCurrencyId,
                    selectedDeliveryId: _selectedDeliveryId,
                    isSaving: rateState.isLoading,
                    onSave: _saveRate
                )
        )
    );
  }

  Future<void> _saveRate() async {
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

    final amount = double.tryParse(_rateController.text) ?? 0.0;
    final currency = ref.read(companyCurrencyProvider).currencies.firstWhereOrNull(
            (c) => c.id.toString() == _selectedCurrencyId);
    final delivery = ref.read(deliveryProvider).deliveries.firstWhereOrNull(
            (c) => c.id.toString() == _selectedDeliveryId);

    if (currency == null || delivery == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'La moneda o remesero seleccionado ya no son válidos.',
          type: SnackBarType.error);
      return;
    }

    final rateToSave = Rate(
        currencyId: currency.id!,
        name: currency.name,
        fullName: currency.fullName,
        symbol: currency.symbol,
        rate: amount,
        partnerId: delivery.id!);

    await ref.read(rateProvider.notifier).addRate(rateToSave);
  }

}

class _RateForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController rateController;
  final VoidCallback onSave;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String?> onDeliveryChanged;
  final String? selectedCurrencyId;
  final String? selectedDeliveryId;
  final bool isSaving;

  const _RateForm({
    required this.formKey,
    required this.rateController,
    required this.onSave,
    required this.onCurrencyChanged,
    required this.onDeliveryChanged,
    required this.isSaving,
    this.selectedCurrencyId,
    this.selectedDeliveryId
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final currencyState = ref.watch(companyCurrencyProvider);
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
                    Icons.currency_exchange_outlined,
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
                  controller: rateController,
                  isRequired: true,
                  validator: (value) => FormValidators.validateDouble(value)
                ),

                const SizedBox(height: 40),

                FilledButton.tonalIcon(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
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

  Widget _buildCurrencyDropdown(BuildContext context, WidgetRef ref, CompanyCurrencyState state, ValueChanged<String?> onChanged, String? selectedId) {
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
                  ref.read(companyCurrencyProvider.notifier).loadCurrencies();
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
    );
  }

}
