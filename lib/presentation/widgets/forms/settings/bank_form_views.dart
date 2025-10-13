import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/bank.dart';
import 'package:yo_te_pago/business/providers/banks_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';

class BanksFormView extends ConsumerStatefulWidget {

  static const String name = AppRoutes.banksCreate;

  final Bank? bank;

  const BanksFormView({super.key, this.bank});

  @override
  ConsumerState<BanksFormView> createState() => _BanksFormViewState();

}

class _BanksFormViewState extends ConsumerState<BanksFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  late final bool _isEditing;

  @override
  void initState() {
    super.initState();

    _isEditing = widget.bank != null;
    if (_isEditing) {
      _nameController.text = widget.bank!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final bankState = ref.watch(bankProvider);

    ref.listen(bankProvider, (previous, next) {
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
            title: Text(_isEditing ? AppTitles.bankEdit : AppTitles.bank),
            centerTitle: true
        ),
        body: SafeArea(
            child: (bankState.isLoading && bankState.banks.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _BankForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      isSaving: bankState.isLoading,
                      onSave: _saveBank
                  )
        )
    );
  }

  Future<void> _saveBank() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.formHasErrors,
          type: SnackBarType.warning);

      return;
    }

    if (_isEditing) {
      final updatedBank = widget.bank!.copyWith(name: _nameController.text);
      await ref.read(bankProvider.notifier).updateBank(updatedBank);
    } else {
      final bankToSave = Bank(name: _nameController.text);
      await ref.read(bankProvider.notifier).addBank(bankToSave);
    }
  }

}

class _BankForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final VoidCallback onSave;
  final bool isSaving;

  const _BankForm({
    required this.formKey,
    required this.nameController,
    required this.isSaving,
    required this.onSave
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                      Icons.domain_add_rounded,
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


}