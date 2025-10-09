import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_record_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/app_validation.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/config/helpers/human_formats.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/accounts_provider.dart';
import 'package:yo_te_pago/business/providers/rates_provider.dart';
import 'package:yo_te_pago/business/providers/remittances_provider.dart';
import 'package:yo_te_pago/presentation/routes/app_router.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/date_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/decimal_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/time_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class RemittanceFormView extends ConsumerStatefulWidget {

  static const name = 'remittance';
  final int? id;

  const RemittanceFormView({
    super.key,
    this.id
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

  String? _selectedRateId;
  String? _selectedAccountId;
  Remittance? _remittance;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(rateProvider).rates.isEmpty) {
        ref.read(rateProvider.notifier).loadRates();
      }
      if (ref.read(accountProvider).accounts.isEmpty) {
        ref.read(accountProvider.notifier).loadAccounts();
      }

      _initializeFormData();
    });
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
    final rateState = ref.watch(rateProvider);
    final accountState = ref.watch(accountProvider);

    final String appBarTitle = widget.id != null
        ? AppTitles.remittanceEdit
        : AppTitles.remittanceCreate;

    final goBackLocation = ref.read(appRouterProvider).namedLocation(AppRoutes.home, pathParameters: {'page': '0'});

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(goBackLocation)
        )
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
                  onSave: _saveRemittance,
                  remittance: _remittance
              )
      )
    );
  }

  void _initializeFormData() {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final goBackLocation = ref.read(appRouterProvider).namedLocation(AppRoutes.home, pathParameters: {'page': '0'});

    if (widget.id != null) {
      final remittance = ref.read(remittanceProvider).remittances.firstWhereOrNull(
              (c) => c.id == widget.id);

      if (remittance != null) {
        _amountController.text = remittance.amount.toString();
        _codeController.text = remittance.code ?? '';
        _customerController.text = remittance.customer;
        _dateController.text = HumanFormats.toShortDate(remittance.createdAt);
        _timeController.text = HumanFormats.toShortTime(remittance.createdAt);

        setState(() {
          _remittance = remittance;
          _selectedRateId = remittance.currencyId.toString();
          _selectedAccountId = remittance.bankAccountId.toString();
        });
      } else {
        showCustomSnackBar(
            scaffoldMessenger: scaffoldMessenger,
            message: 'Error: No se encontró la remesa seleccionada.',
            type: SnackBarType.error);

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(goBackLocation);
        }
      }
    } else {
      final now = DateTime.now();
      _dateController.text = HumanFormats.toShortDate(now);
      _timeController.text = HumanFormats.toShortTime(now);
    }
  }

  Future<void> _saveRemittance() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final goBackLocation = ref.read(appRouterProvider).namedLocation(AppRoutes.home, pathParameters: {'page': '0'});

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppRecordMessages.formHasErrors,
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

    try {
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

      Remittance remittanceToSave;

      if (_remittance == null) {
        remittanceToSave = Remittance(
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
      } else {
        remittanceToSave = _remittance!.copyWith(
            customer: customer,
            amount: amount,
            code: code,
            createdAt: createDate,
            currencyId: rate.currencyId,
            currencyName: rate.name,
            currencySymbol: rate.symbol,
            rate: rate.rate,
            bankAccountId: account.id!,
            bankAccountName: account.name,
            bankName: account.bankName
        );
        await ref.read(remittanceProvider.notifier).editRemittance(remittanceToSave);
      }

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
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Ocurrió un error inesperado.',
          type: SnackBarType.error);
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
  final Remittance? remittance;

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
    this.selectedAccountId,
    this.selectedRateId,
    this.remittance
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final rateState = ref.watch(rateProvider);
    final accountState = ref.watch(accountProvider);

    final bool isNewRecord = remittance == null;
    final String labelButton = isNewRecord ? AppButtons.save : AppButtons.update;

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
                  enabled: isNewRecord,
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
                        enabled: isNewRecord,
                        isRequired: true
                      )
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomTextFormField(
                        label: AppFormLabels.code,
                        controller: codeController,
                        enabled: isNewRecord
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
                        enabled: isNewRecord,
                        isRequired: true
                      )
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TimePickerFormField(
                        label: AppFormLabels.time,
                        controller: timeController,
                        validator: (value) => FormValidators.validateRequired(value),
                        enabled: isNewRecord,
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
                    onPressed: onSave,
                    icon: const Icon(Icons.save),
                    label: Text(labelButton)
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
