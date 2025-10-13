import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yo_te_pago/business/config/constants/app_messages.dart';

import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/app_validation.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/providers/bank_accounts_provider.dart';
import 'package:yo_te_pago/business/providers/banks_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/input/dropdown_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';

class BankAccountFormView extends ConsumerStatefulWidget {

  static const String name = AppRoutes.bankAccountCreate;

  final BankAccount? bankAccount;

  const BankAccountFormView({super.key, this.bankAccount});

  @override
  ConsumerState<BankAccountFormView> createState() => _BankAccountFormViewState();

}

class _BankAccountFormViewState extends ConsumerState<BankAccountFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  late final bool _isEditing;
  String? _selectedBankId;

  @override
  void initState() {
    super.initState();

    _isEditing = widget.bankAccount != null;
    if (_isEditing) {
      _nameController.text = widget.bankAccount!.name;
      _selectedBankId = widget.bankAccount!.bankId.toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(bankProvider).banks.isEmpty) {
        ref.read(bankProvider.notifier).loadBanks();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final bankAccountState = ref.watch(bankAccountProvider);
    final bankState = ref.watch(bankProvider);

    ref.listen(bankAccountProvider, (previous, next) {
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
            title: Text(_isEditing ? AppTitles.bankAccountEdit : AppTitles.bankAccountAdd),
            centerTitle: true
        ),
        body: SafeArea(
            child: (bankAccountState.isLoading || bankState.isLoading)
                ? const Center(child: CircularProgressIndicator())
                : _BankAccountForm(
                formKey: _formKey,
                nameController: _nameController,
                onBankChanged: (value) => setState(() => _selectedBankId = value),
                selectedBankId: _selectedBankId,
                isSaving: bankAccountState.isLoading,
                isEditing: _isEditing,
                onSave: _saveBankAccount)
        )
    );
  }

  Future<void> _saveBankAccount() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.formHasErrors,
          type: SnackBarType.warning);

      return;
    }

    if (_selectedBankId == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppValidationMessages.selectionRequired,
          type: SnackBarType.warning);
      return;
    }
    final bankId = int.tryParse(_selectedBankId!);

    if (bankId == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'El banco seleccionado no es válido.',
          type: SnackBarType.error);
      return;
    }

    if (_isEditing) {
      final updatedBankAccount = widget.bankAccount!.copyWith(name: _nameController.text);
      await ref.read(bankAccountProvider.notifier).updateBankAccount(updatedBankAccount);
    } else {
      final bankAccountToSave = BankAccount(name: _nameController.text, bankId: bankId);
      await ref.read(bankAccountProvider.notifier).addBankAccount(bankAccountToSave);
    }
  }

}

class _BankAccountForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final VoidCallback onSave;
  final ValueChanged<String?> onBankChanged;
  final String? selectedBankId;
  final bool isSaving;
  final bool isEditing;

  const _BankAccountForm({
    required this.formKey,
    required this.onSave,
    required this.nameController,
    required this.onBankChanged,
    this.selectedBankId,
    this.isEditing = false,
    this.isSaving = false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final bankState = ref.watch(bankProvider);

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

                  CustomTextFormField(
                      label: AppFormLabels.name,
                      controller: nameController,
                      isRequired: true,
                      validator: (value) => FormValidators.validateRequired(value)
                  ),

                  const SizedBox(height: 20),

                  _buildBankDropdown(context, ref, bankState, onBankChanged, selectedBankId, isEditing),

                  const SizedBox(height: 40),

                  FilledButton.tonalIcon(
                      onPressed: isSaving ? null : onSave,
                      icon: isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(AppButtons.save)
                  )
                ]
            )
        )
    );

  }

  Widget _buildBankDropdown(BuildContext context, WidgetRef ref, BankState state, ValueChanged<String?> onChanged, String? selectedId, bool isEditing) {
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
                  ref.read(bankProvider.notifier).loadBanks();
                },
                child: const Text(AppButtons.retry)
            )
          ]
      );
    }

    if (state.banks.isEmpty && !state.isLoading) {
      return const Center(
          child: Text(
              'No hay bancos disponibles.',
              textAlign: TextAlign.center
          )
      );
    }

    return ComboBoxPicker(
        hint: AppFormLabels.bankSelect,
        label: AppFormLabels.bank,
        isRequired: true,
        selectedId: selectedId,
        enabled: !isEditing,
        items: state.banks.map((bank) => DropdownMenuItem<String>(
            value: '${bank.id}',
            child: Text(
                bank.name,
                overflow: TextOverflow.ellipsis))
        ).toList(),
        validator: (value) => value == null ? AppValidationMessages.bankSelection : null,
        onChanged: onChanged
    );
  }

}