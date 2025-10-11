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
import 'package:yo_te_pago/business/config/helpers/human_formats.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/providers/accounts_provider.dart';
import 'package:yo_te_pago/business/providers/rates_provider.dart';
import 'package:yo_te_pago/business/providers/remittances_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/date_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/decimal_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/time_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class RemittanceFormView extends ConsumerStatefulWidget {

  static const name = AppRoutes.remittance;

  final Remittance? remittance;

  const RemittanceFormView({
    super.key,
    this.remittance
  });

  @override
  ConsumerState<RemittanceFormView> createState() => _RemittanceFormViewState();

}

class _RemittanceFormViewState extends ConsumerState<RemittanceFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late final bool _isEditing;
  String? _selectedRateId;
  String? _selectedAccountId;
  bool _isInitialLoadAttempted = false;

  @override
  void initState() {
    super.initState();

    _isEditing = widget.remittance != null;

    if (_isEditing) {
      _amountController.text = widget.remittance!.amount.toString();
      _codeController.text = widget.remittance!.code ?? '';
      _customerController.text = widget.remittance!.customer;
      _dateController.text = HumanFormats.toShortDate(widget.remittance!.createdAt);
      _timeController.text = HumanFormats.toShortTime(widget.remittance!.createdAt);
      _selectedRateId = widget.remittance!.currencyId.toString();
      _selectedAccountId = widget.remittance!.bankAccountId.toString();
    } else {
      final now = DateTime.now();
      _dateController.text = HumanFormats.toShortDate(now);
      _timeController.text = HumanFormats.toShortTime(now);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _codeController.dispose();
    _customerController.dispose();
    _dateController.dispose();
    _timeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialLoadAttempted) {
      Future.microtask(() {
        if (ref.read(rateProvider).rates.isEmpty) {
          ref.read(rateProvider.notifier).loadRates();
        }
        if (ref.read(accountProvider).accounts.isEmpty) {
          ref.read(accountProvider.notifier).loadAccounts();
        }
      });
      _isInitialLoadAttempted = true;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final rateState = ref.watch(rateProvider);
    final accountState = ref.watch(accountProvider);
    final remittanceState = ref.watch(remittanceProvider);

    ref.listen(remittanceProvider, (previous, next) {
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
        title: Text(_isEditing ? AppTitles.remittanceEdit : AppTitles.remittanceCreate),
        centerTitle: true
      ),
      body: SafeArea(
          child: (rateState.isLoading || accountState.isLoading)
              ? const Center(child: CircularProgressIndicator())
              : _RemittanceForm(
                  formKey: _formKey,
                  amountController: _amountController,
                  codeController: _codeController,
                  customerController: _customerController,
                  dateController: _dateController,
                  timeController: _timeController,
                  onRateChanged: (value) => setState(() => _selectedRateId = value),
                  onAccountChanged: (value) => setState(() => _selectedAccountId = value),
                  selectedRateId: _selectedRateId,
                  selectedAccountId: _selectedAccountId,
                  isSaving: remittanceState.isLoading,
                  isEditing: _isEditing,
                  onSave: _saveRemittance
              )
      )
    );
  }

  Future<void> _saveRemittance() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.formHasErrors,
          type: SnackBarType.warning);
      return;
    }

    if (_selectedRateId == null || _selectedAccountId == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppValidationMessages.selectionRequired,
          type: SnackBarType.warning);
      return;
    }

    final customer = _customerController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final code = _codeController.text.trim();
    final createDate = HumanFormats.toDateTime('${_dateController.text} ${_timeController.text}');

    final rate = ref.read(rateProvider).rates.firstWhereOrNull(
            (c) => c.currencyId.toString() == _selectedRateId);
    final account = ref.read(accountProvider).accounts.firstWhereOrNull(
            (c) => c.id.toString() == _selectedAccountId);

    if (rate == null || account == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'La tasa o la cuenta seleccionada ya no son válidas.',
          type: SnackBarType.error);
      return;
    }

    if (_isEditing) {
      final updateRemittance = widget.remittance!.copyWith(
          customer: _customerController.text.trim(),
          amount: double.tryParse(_amountController.text) ?? 0.0,
          code: _codeController.text.trim(),
          createdAt: HumanFormats.toDateTime('${_dateController.text} ${_timeController.text}'),
          currencyId: rate.currencyId,
          currencyName: rate.name,
          currencySymbol: rate.symbol,
          rate: rate.rate,
          bankAccountId: account.id!,
          bankAccountName: account.name,
          bankName: account.bankName
      );
      await ref.read(remittanceProvider.notifier).editRemittance(updateRemittance);
    } else {
      final remittanceToSave = Remittance(
          customer: customer,
          amount: amount,
          code: code,
          createdAt: createDate,
          state: 'waiting',
          currencyId: rate.currencyId,
          currencyName: rate.name,
          currencySymbol: rate.symbol,
          rate: rate.rate,
          bankAccountId: account.id!,
          bankAccountName: account.name,
          bankName: account.bankName
      );
      await ref.read(remittanceProvider.notifier).addRemittance(remittanceToSave);
    }
  }

}

class _RemittanceForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController codeController;
  final TextEditingController customerController;
  final TextEditingController dateController;
  final TextEditingController timeController;
  final VoidCallback onSave;
  final ValueChanged<String?> onRateChanged;
  final ValueChanged<String?> onAccountChanged;
  final String? selectedRateId;
  final String? selectedAccountId;
  final bool isEditing;
  final bool isSaving;

  const _RemittanceForm({
    required this.formKey,
    required this.amountController,
    required this.codeController,
    required this.customerController,
    required this.dateController,
    required this.timeController,
    required this.onSave,
    required this.onAccountChanged,
    required this.onRateChanged,
    required this.isEditing,
    required this.isSaving,
    this.selectedAccountId,
    this.selectedRateId
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final rateState = ref.watch(rateProvider);
    final accountState = ref.watch(accountProvider);

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                    Icons.add_card,
                    color: colors.primary,
                    size: 80
                ),

                const SizedBox(height: 40),

                CustomTextFormField(
                  label: AppFormLabels.customer,
                  controller: customerController,
                  validator: (value) => FormValidators.validateRequired(value),
                  enabled: !isEditing,
                  isRequired: true
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: DecimalTextFormField(
                        label: AppFormLabels.amount,
                        controller: amountController,
                        validator: (value) => FormValidators.validateDouble(value),
                        enabled: !isEditing,
                        isRequired: true
                      )
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomTextFormField(
                        label: AppFormLabels.code,
                        controller: codeController,
                        enabled: !isEditing
                      )
                    )
                  ]
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: DatePickerFormField(
                        label: AppFormLabels.date,
                        controller: dateController,
                        validator: (value) => FormValidators.validateRequired(value),
                        enabled: !isEditing,
                        isRequired: true
                      )
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TimePickerFormField(
                        label: AppFormLabels.time,
                        controller: timeController,
                        validator: (value) => FormValidators.validateRequired(value),
                        enabled: !isEditing,
                        isRequired: true
                      )
                    )
                  ]
                ),

                const SizedBox(height: 20),

                _buildAccountComboBox(context, ref, accountState, onAccountChanged, selectedAccountId),

                const SizedBox(height: 20),

                _buildCurrencyComboBox(context, ref, rateState, onRateChanged, selectedRateId),

                const SizedBox(height: 40),

                FilledButton.tonalIcon(
                    onPressed: isSaving ? null : onSave,
                    icon: const Icon(Icons.save),
                    label: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(AppButtons.save)
                )
              ]
            )
        )
    );
  }

  Widget _buildCurrencyComboBox(BuildContext context, WidgetRef ref, RateState state, ValueChanged<String?> onChanged, String? selectedId) {

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
                  ref.read(rateProvider.notifier).loadRates();
                },
                child: const Text(AppButtons.retry)
            )
          ]
      );
    }

    if (state.rates.isEmpty && !state.isLoading) {
      return const Center(
        child: Text(
          'No hay tasas disponibles. Por favor, agregue una.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ComboBoxPicker(
        hint: AppFormLabels.paymentCurrency,
        label: AppFormLabels.currency,
        isRequired: true,
        selectedId: selectedId,
        items: state.rates.map((rate) => DropdownMenuItem<String>(
            value: rate.currencyId.toString(),
            child: Text(
                rate.toString(),
                overflow: TextOverflow.ellipsis))
        ).toList(),
        validator: (value) => value == null ? AppValidationMessages.currencySelection : null,
        onChanged: onChanged
    );
  }

  Widget _buildAccountComboBox(BuildContext context, WidgetRef ref, AccountState state, ValueChanged<String?> onChanged, String? selectedId) {

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
                  ref.read(accountProvider.notifier).loadAccounts();
                },
                child: const Text(AppButtons.retry)
            )
          ]
      );
    }

    if (state.accounts.isEmpty && !state.isLoading) {
      return const Center(
        child: Text(
          'No hay cuentas bancarias disponibles. Por favor, agregue una.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ComboBoxPicker(
        hint: AppFormLabels.bankAccount,
        label: AppFormLabels.accountBank,
        isRequired: true,
        selectedId: selectedId,
        items: state.accounts.map((account) => DropdownMenuItem<String>(
            value: account.id.toString(),
            child: Text(
                account.toString(),
                overflow: TextOverflow.ellipsis))
        ).toList(),
        validator: (value) => value == null ? AppValidationMessages.accountSelection : null,
        onChanged: onChanged
    );
  }

}
