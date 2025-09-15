import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/config/constants/app_record_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_remittance_states.dart';
import 'package:yo_te_pago/business/config/constants/app_validation.dart';
import 'package:yo_te_pago/business/config/constants/bottom_bar_items.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/providers/delivery_provider.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/business/providers/rate_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';

class BalanceFormView extends StatefulWidget {

  static const name = 'balance-form-views';

  const BalanceFormView({
    super.key
  });

  @override
  State<BalanceFormView> createState() => _BalanceFormViewState();

}

class _BalanceFormViewState extends State<BalanceFormView> {

  @override
  Widget build(BuildContext context) {
    String location = appBottomNavigationItems['balance']!.path;

    return Scaffold(
        appBar: AppBar(
            title: Text(AppTitles.balanceCreate),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.go(location),
            )
        ),
        body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _BalanceForm()
              ),
            )
        )
    );
  }
}

class _BalanceForm extends ConsumerStatefulWidget {

  const _BalanceForm();

  @override
  ConsumerState<_BalanceForm> createState() => _BalanceFormState();

}

class _BalanceFormState extends ConsumerState<_BalanceForm> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _selectedCurrencyId = '';
  String _selectedDeliveryId = '';

  final TextEditingController _amountController = TextEditingController();

  Future<bool> _saveData(int sign) async {
    if (!mounted) {
      return false;
    }
    final rateState = ref.read(rateProvider);
    final deliveryState = ref.read(deliveryProvider);
    final currencies = rateState.currencies;
    final deliveries = deliveryState.deliveries;
    final odooService = ref.read(odooServiceProvider);
    double credit = 0;
    double debit = 0;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount == 0) {
      showCustomSnackBar(
        context: context,
        message: AppValidationMessages.positiveNumber,
        type: SnackBarType.error,
      );
      return false;
    }
    if (sign > 0) {
      credit = amount;
    } else {
      debit = amount;
    }

    if (currencies.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: AppNetworkMessages.errorNoCurrencies,
        type: SnackBarType.error,
      );
      return false;
    }
    if (deliveries.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: AppNetworkMessages.errorNoDeliveries,
        type: SnackBarType.error,
      );
      return false;
    }
    final currency = currencies.firstWhere(
            (c) => c.currencyId.toString() == _selectedCurrencyId,
        orElse: () => throw Exception(AppNetworkMessages.errorNoCurrencies)
    );
    final delivery = deliveries.firstWhere(
            (c) => c.id.toString() == _selectedDeliveryId,
        orElse: () => throw Exception(AppNetworkMessages.errorNoDeliveries)
    );
    if (sign > 0) {

    }
    final balance = Balance(
        currencyId: currency.currencyId,
        name: currency.name,
        fullName: currency.fullName,
        symbol: currency.symbol,
        partnerId: delivery.id!,
        partnerName: delivery.name,
        debit: debit,
        credit: credit);

    try {
      await odooService.addBalance(balance);
      if (!mounted) {
        return false;
      }
      showCustomSnackBar(
        context: context,
        message: AppRecordMessages.registerSuccess,
        type: SnackBarType.success,
      );

      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      showCustomSnackBar(
          context: context,
          message: e.toString(),
          type: SnackBarType.error
      );
      return false;
    }
  }

  void _clearControllers() {
    _amountController.clear();
    _selectedCurrencyId = '';
    _selectedDeliveryId = '';
  }

  Widget _buildCurrencyDropdown() {
    final rateState = ref.watch(rateProvider);
    final currencies = rateState.currencies;

    if (rateState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (rateState.errorMessage != null) {
      return Column(
          children: [
            Text(
                'Error al cargar monedas: ${rateState.errorMessage}. Por favor, intente recargar.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  ref.read(rateProvider.notifier).loadCurrencies();
                },
                child: const Text(AppButtons.retry)
            ),
          ]
      );
    } else if (currencies.isEmpty) {
      return Text(
          AppNetworkMessages.errorNoCurrencies,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center
      );
    } else {
      return ComboBoxPicker(
          hint: AppFormLabels.paymentCurrency,
          label: AppFormLabels.currency,
          isRequired: true,
          selectedId: _selectedCurrencyId,
          items: currencies.map((currency) =>
              DropdownMenuItem<String>(
                  value: '${currency.currencyId}',
                  child: Text(
                      currency.toString(),
                      overflow: TextOverflow.ellipsis)
              )).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppValidationMessages.currencySelection;
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedCurrencyId = value!.trim();
            });
          }
      );
    }
  }

  Widget _buildDeliveryDropdown() {
    final deliveryState = ref.watch(deliveryProvider);
    final deliveries = deliveryState.deliveries;

    if (deliveryState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (deliveryState.errorMessage != null) {
      return Column(
          children: [
            Text(
                'Error al cargar remeseros: ${deliveryState.errorMessage}. Por favor, intente recargar.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  ref.read(deliveryProvider.notifier).loadDeliveries();
                },
                child: const Text(AppButtons.retry)
            ),
          ]
      );
    } else if (deliveries.isEmpty) {
      return Text(
          AppNetworkMessages.errorNoDeliveries,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center
      );
    } else {
      return ComboBoxPicker(
          hint: AppFormLabels.username,
          label: AppFormLabels.delivery,
          isRequired: true,
          selectedId: _selectedDeliveryId,
          items: deliveries.map((delivery) =>
              DropdownMenuItem<String>(
                  value: '${delivery.id}',
                  child: Text(
                      delivery.name,
                      overflow: TextOverflow.ellipsis)
              )).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppValidationMessages.deliverySelection;
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedDeliveryId = value!.trim();
            });
          }
      );
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(rateProvider.notifier).loadCurrencies();
      ref.read(deliveryProvider.notifier).loadDeliveries();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rateState = ref.watch(rateProvider);
    final deliveryState = ref.watch(deliveryProvider);
    String location = appBottomNavigationItems['balance']!.path;

    final currencies = rateState.currencies;
    final deliveries = deliveryState.deliveries;

    if (rateState.isLoading || deliveryState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (currencies.isEmpty || deliveries.isEmpty) {
      return Center(
        child: Text(
          AppRemittanceMessages.noData,
          style: TextStyle(color: colors.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                  Icons.shopify_outlined,
                  color: colors.primary,
                  size: 60
              ),

              const SizedBox(height: 30),

              _buildDeliveryDropdown(),

              const SizedBox(height: 20),

              _buildCurrencyDropdown(),

              const SizedBox(height: 20),

              CustomTextFormField(
                label: AppFormLabels.amount,
                controller: _amountController,
                validator: (value) => FormValidators.validateInteger(value),
                enabled: true,
                isRequired: true,),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                      onPressed: () async {
                        final form = _formKey.currentState;
                        if (form == null || !form.validate()) {
                          return;
                        }
                        try {
                          final success = await _saveData(1);
                          if (success && context.mounted) {
                            _clearControllers();
                            context.go(location);
                          }
                        } catch (e) {
                          if (!context.mounted) {
                            return;
                          }
                          showCustomSnackBar(
                              context: context,
                              message: AppRecordMessages.registerFailure,
                              type: SnackBarType.error
                          );
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(AppButtons.inCash)
                  ),
                  FilledButton.tonalIcon(
                      onPressed: () async {
                        final form = _formKey.currentState;
                        if (form == null || !form.validate()) {
                          return;
                        }
                        try {
                          final success = await _saveData(-1);
                          if (success && context.mounted) {
                            _clearControllers();
                            context.go(location);
                          }
                        } catch (e) {
                          if (!context.mounted) {
                            return;
                          }
                          showCustomSnackBar(
                              context: context,
                              message: AppRecordMessages.registerFailure,
                              type: SnackBarType.error
                          );
                        }
                      },
                      icon: const Icon(Icons.remove),
                      label: Text(AppButtons.outCash)
                  ),
                ],
              )
            ]
        )
    );
  }
}

