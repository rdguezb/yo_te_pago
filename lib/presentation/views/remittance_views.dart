import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/configs.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/constants/validation_messages.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/config/helpers/human_formats.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/providers/currency_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/business/providers/remittance_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/currency_dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/date_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/decimal_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/time_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class RemittanceView extends StatefulWidget {

  static const name = 'remittance-views';
  final int? id;

  const RemittanceView({
    super.key,
    this.id
  });

  @override
  State<RemittanceView> createState() => _RemittanceViewState();

}

class _RemittanceViewState extends State<RemittanceView> {

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = widget.id != null
        ? AppTitles.remittanceEdit
        : AppTitles.remittanceCreate;
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppConfig.rootPath),
        )
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _RemittanceForm(id: widget.id)
            ),
          )),
    );
  }

}

class _RemittanceForm extends ConsumerStatefulWidget {

  final int? id;

  const _RemittanceForm({
    this.id
  });

  @override
  ConsumerState<_RemittanceForm> createState() => _RemittanceFormState();

}

class _RemittanceFormState extends ConsumerState<_RemittanceForm> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _selectedCurrencyId = '';
  bool _isLoadingRemittance = false;
  bool _isFormEditable = true;
  Remittance? _remittance;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  Future<bool> _saveRemittance() async {
    if (!mounted) {
      return false;
    }
    final odooService = ref.read(odooServiceProvider);
    final currenciesState = ref.read(currencyProvider);

    if (currenciesState.currencies.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: AppStates.noCurrencies,
        type: SnackBarType.error,
      );
      return false;
    }
    final customer = _customerController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final code = _codeController.text.trim();
    final createDate = HumanFormats.toDateTime('${_dateController.text} ${_timeController.text}');
    final currency = currenciesState.currencies.firstWhere(
      (c) => c.id.toString() == _selectedCurrencyId,
      orElse: () => throw Exception(AppStates.noCurrencies)
    );

    final remittanceToSave = Remittance(
        id: _remittance?.id,
        customer: customer,
        amount: amount,
        code: code,
        currencyId: currency.id,
        createdAt: createDate,
        rate: currency.rate
    );

    try {
      if (remittanceToSave.id == null) {
        await odooService.addRemittance(remittanceToSave);
        if (!mounted) {
          return false;
        }
        showCustomSnackBar(
          context: context,
          message: AppStates.registerSuccess,
          type: SnackBarType.success,
        );
      } else {
        await odooService.editRemittance(remittanceToSave);
        if (!mounted) {
          return false;
        }
        showCustomSnackBar(
          context: context,
          message: AppStates.registerSuccess,
          type: SnackBarType.success,
        );
      }
      ref.read(remittanceProvider.notifier).loadRemittances();

      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      showCustomSnackBar(
          context: context,
          message: 'Error al guardar la remesa: ${e.toString()}',
          type: SnackBarType.error
      );
      return false;
    }
  }

  void _clearControllers() {
    _customerController.clear();
    _codeController.clear();
    _amountController.clear();
    _selectedCurrencyId = '';
    _remittance = null;
    _isFormEditable = true;
    final now = DateTime.now();
    _dateController.text = HumanFormats.toShortDate(now);
    _timeController.text = HumanFormats.toShortDate(now);
  }

  Future<void> _loadRemittance(int id) async {
    setState(() {
      _isLoadingRemittance = true;
      _isFormEditable = false;
    });
    try {
      final odooService = ref.read(odooServiceProvider);
      final remittances = await odooService.getRemittances(id: id);
      if (!mounted) {
        return;
      }
      if (remittances.isEmpty) {
        throw Exception(AppStates.noRemittance);
      }
      final Remittance loadedRemittance = remittances.first;

      setState(() {
        _remittance = loadedRemittance;
        _isLoadingRemittance = false;
        _isFormEditable = loadedRemittance.state == 'waiting';
        _fillFormWithRemittance(loadedRemittance);
      });

      if (!_isFormEditable) {
        showCustomSnackBar(
          context: context,
          message: AppStates.remittanceConfirmed,
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingRemittance = false;
        _isFormEditable = false;
      });
      showCustomSnackBar(
        context: context,
        message: 'Error al cargar la remesa: ${e.toString()}',
        type: SnackBarType.error,
      );
      context.go(AppConfig.rootPath);
    }
  }

  void _fillFormWithRemittance(Remittance remittance) {
    _customerController.text = remittance.customer;
    _amountController.text = HumanFormats.toAmount(remittance.amount);
    _codeController.text = remittance.code ?? '';
    _dateController.text = HumanFormats.toShortDate(remittance.createdAt);
    _timeController.text = HumanFormats.toShortTime(remittance.createdAt);
    _selectedCurrencyId = remittance.currencyId.toString();
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(currencyProvider.notifier).loadCurrencies();
    });
    if (widget.id != null) {
      _loadRemittance(widget.id!);
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
    final colors = Theme.of(context).colorScheme;
    final currenciesState = ref.watch(currencyProvider);
    final List<Currency> currencies = currenciesState.currencies;
    final bool isLoadingCurrencies = currenciesState.isLoading;
    final String? currencyErrorMessage = currenciesState.errorMessage;

    ref.listen<CurrencyState>(currencyProvider, (previousState, newState) {
      if (!newState.isLoading &&
          newState.currencies.isNotEmpty &&
          _isFormEditable &&
          _selectedCurrencyId.isEmpty &&
          widget.id == null
      ) {
        setState(() {
          _selectedCurrencyId = newState.currencies.first.id.toString();
        });
      }
    });

    if (_isLoadingRemittance) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.id != null && _remittance == null && !_isLoadingRemittance) {
      return Center(
        child: Text(
          AppStates.noRemittance,
          style: TextStyle(color: colors.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Form(
      key: _formKey,
      autovalidateMode: _isFormEditable
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
              Icons.add_card,
              color: colors.primary,
              size: 60
          ),

          const SizedBox(height: 30),

          CustomTextFormField(
            label: AppFormLabels.customer,
            controller: _customerController,
            validator: (value) => FormValidators.validateRequired(value),
            enabled: _isFormEditable,
            isRequired: true,
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: DecimalTextFormField(
                  label: AppFormLabels.amount,
                  controller: _amountController,
                  validator: (value) => FormValidators.validateInteger(value),
                  enabled: _isFormEditable,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: CustomTextFormField(
                  label: AppFormLabels.code,
                  controller: _codeController,
                  enabled: _isFormEditable,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: DatePickerFormField(
                  label: AppFormLabels.date,
                  controller: _dateController,
                  validator: (value) => FormValidators.validateRequired(value),
                  enabled: _isFormEditable,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TimePickerFormField(
                  label: AppFormLabels.time,
                  controller: _timeController,
                  validator: (value) => FormValidators.validateRequired(value),
                  enabled: _isFormEditable,
                  isRequired: true,
                ),
              )
            ],
          ),

          const SizedBox(height: 20),

          if (isLoadingCurrencies)
            const Center(child: CircularProgressIndicator())
          else if (currencyErrorMessage != null)
            Column(
              children: [
                Text(
                  'Error al cargar monedas: $currencyErrorMessage. Por favor, intente recargar.',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    ref.read(currencyProvider.notifier).loadCurrencies();
                  },
                  child: const Text(AppButtons.retry),
                ),
              ],
            )
          else if (currencies.isEmpty)
              Text(AppStates.noCurrencies,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              )
          else
            CurrencyPicker(
              hint: AppFormLabels.paymentCurrency,
              label: AppFormLabels.currency,
              isRequired: true,
              selectedId: _selectedCurrencyId,
              items: currencies.map((currency) => DropdownMenuItem<String>(
                value: '${currency.id}',
                child: Text('[${currency.name}] ${currency.fullName}'),
              )).toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppValidation.currencySelection;
                }
                return null;
              },
              onChanged: _isFormEditable
                  ? (value) {
                      setState(() {
                        _selectedCurrencyId = value!.trim();
                      });
                    }
                  : null
            ),

          const SizedBox(height: 20),

          if (_isFormEditable)
            FilledButton.tonalIcon(
              onPressed: () async {
                final form = _formKey.currentState;
                if (form == null || !form.validate()) {
                  return;
                }
                try {
                  final success = await _saveRemittance();
                  if (success && context.mounted) {
                    _clearControllers();
                    context.go(AppConfig.rootPath);
                  }
                } catch (e) {
                  if (!context.mounted) {
                    return;
                  }
                  showCustomSnackBar(
                    context: context,
                    message: AppStates.registerFailure,
                    type: SnackBarType.error
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: Text(widget.id != null
                  ? AppButtons.update
                  : AppButtons.save)
            ),
          if (!_isFormEditable && widget.id != null)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                AppStates.remittanceConfirmed,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic
                ),
                textAlign: TextAlign.center
              )
            ),
        ]
      )
    );
  }

}
