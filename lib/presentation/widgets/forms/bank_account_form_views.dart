import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
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


class BankAccountFormView extends StatefulWidget {

  static const name = 'bank-account-form-views';

  const BankAccountFormView({
    super.key
  });

  @override
  State<BankAccountFormView> createState() => _BankAccountFormViewState();

}

class _BankAccountFormViewState extends State<BankAccountFormView> {

  @override
  Widget build(BuildContext context) {
    String location = appBottomNavigationItems['bank']!.path;

    return Scaffold(
        appBar: AppBar(
            title: Text(AppTitles.bankAccountLink),
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
                  child: _BankAccountForm()
              ),
            )
        )
    );
  }

}

class _BankAccountForm extends ConsumerStatefulWidget {

  const _BankAccountForm();

  @override
  _BankAccountFormState createState() => _BankAccountFormState();

}

class _BankAccountFormState extends ConsumerState<_BankAccountForm> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _selectedAccountId = '';
  String _selectedDeliveryId = '';

  Future<bool> _saveData() async {
    if (!mounted) {
      return false;
    }
    final deliveryState = ref.read(deliveryProvider);
    final accountState = ref.read(accountProvider);
    final accounts = accountState.allowedAccounts;
    final deliveries = deliveryState.deliveries;
    final odooService = ref.read(odooServiceProvider);

    if (accounts.isEmpty) {
      showCustomSnackBar(
        context: context,
        message: AppNetworkMessages.errorNoBankAccount,
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

    final account = accounts.firstWhere(
            (c) => c.id.toString() == _selectedAccountId,
        orElse: () => throw Exception(AppNetworkMessages.errorNoCurrencies)
    );
    final delivery = deliveries.firstWhere(
            (c) => c.id.toString() == _selectedDeliveryId,
        orElse: () => throw Exception(AppNetworkMessages.errorNoBankAccount)
    );

    final accountToSave = account.copyWith(
        partnerId: delivery.id,
        partnerName: delivery.name
    );

    try {
      await odooService.linkBankAccount(accountToSave);

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
    _selectedAccountId = '';
    _selectedDeliveryId = '';
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
                '${deliveryState.errorMessage}. Por favor, intente recargar.',
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

  Widget _buildAccountDropdown() {
    final accountState = ref.watch(accountProvider);
    final accounts = accountState.allowedAccounts;

    if (accountState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (accountState.errorMessage != null && accounts.isEmpty) {
      return Column(
          children: [
            Text(
                '${accountState.errorMessage}. Por favor, intente recargar.',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () {
                  ref.read(accountProvider.notifier).loadAllowedAccounts();
                },
                child: const Text(AppButtons.retry)
            ),
          ]
      );
    } else if (accounts.isEmpty) {
      return Text(
          AppNetworkMessages.errorNoBankAccount,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center
      );
    } else {
      return ComboBoxPicker(
          hint: AppFormLabels.bankAccount,
          label: AppFormLabels.accountBank,
          isRequired: true,
          selectedId: _selectedAccountId,
          items: accounts.map((account) =>
              DropdownMenuItem<String>(
                  value: '${account.id}',
                  child: Text(
                      account.toString(),
                      overflow: TextOverflow.ellipsis)
              )).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppValidationMessages.accountSelection;
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _selectedAccountId = value!.trim();
            });
          }
      );
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(accountProvider.notifier).loadAllowedAccounts();
      ref.read(deliveryProvider.notifier).loadDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accountState = ref.watch(accountProvider);
    final deliveryState = ref.watch(deliveryProvider);
    String location = appBottomNavigationItems['bank']!.path;

    if (accountState.isLoading || deliveryState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                  Icons.account_balance_rounded,
                  color: colors.primary,
                  size: 60
              ),

              const SizedBox(height: 30),

              _buildDeliveryDropdown(),

              const SizedBox(height: 20),

              _buildAccountDropdown(),

              const SizedBox(height: 20),

              FilledButton.tonalIcon(
                  onPressed: () async {
                    final form = _formKey.currentState;
                    if (form == null || !form.validate()) {
                      return;
                    }
                    try {
                      final success = await _saveData();
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
                  icon: const Icon(Icons.save),
                  label: Text(AppButtons.save)
              )
            ]
        )
    );

  }

}