import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_record_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_validation.dart';
import 'package:yo_te_pago/business/config/constants/bottom_bar_items.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/providers/currency_provider.dart';
import 'package:yo_te_pago/business/providers/delivery_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class RateFormView extends ConsumerStatefulWidget {

  static const name = 'rate-form-views';

  const RateFormView({
    super.key,
  });

  @override
  ConsumerState<RateFormView> createState() => _RateFormViewState();

}

class _RateFormViewState extends ConsumerState<RateFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final String goBackLocation = appBottomNavigationItems['rate']!.path;
  final TextEditingController _rateController = TextEditingController();

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
    _rateController.dispose();

    super.dispose();
  }

  Future<void> _saveRate() async {
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
    final amount = double.tryParse(_rateController.text) ?? 0.0;

    try {
      final currency = ref.read(currencyProvider).currencies.firstWhere(
              (c) => c.id.toString() == _selectedCurrencyId);
      final delivery = ref.read(deliveryProvider).deliveries.firstWhere(
              (c) => c.id.toString() == _selectedDeliveryId);

      final rate = Rate(
          currencyId: currency.id!,
          name: currency.name,
          fullName: currency.fullName,
          symbol: currency.symbol,
          rate: amount,
          partnerId: delivery.id!);

      await odooService.addRate(rate);

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
            title: Text(AppTitles.rateCreate),
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
                : _RateForm(
                    formKey: _formKey,
                    rateController: _rateController,
                    onCurrencyChanged: (value) => setState(() => _selectedCurrencyId = value),
                    onDeliveryChanged: (value) => setState(() => _selectedDeliveryId = value),
                    selectedCurrencyId: _selectedCurrencyId,
                    selectedDeliveryId: _selectedDeliveryId,
                    onSave: _saveRate
                )
        )
    );
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

  const _RateForm({
    required this.formKey,
    required this.rateController,
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
                    Icons.currency_exchange_outlined,
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
                  controller: rateController,
                  isRequired: true,
                  validator: (value) => FormValidators.validateRequired(value)),

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
    );
  }

}
