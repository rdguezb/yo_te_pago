import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yo_te_pago/business/config/constants/app_record_messages.dart';

import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';

class MyAccountFormView extends ConsumerStatefulWidget {

  static const String name = 'my-account-form-view';

  const MyAccountFormView({super.key});

  @override
  ConsumerState<MyAccountFormView> createState() => _MyAccountFormViewState();

}

class _MyAccountFormViewState extends ConsumerState<MyAccountFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final String goBackLocation = '/home/4';
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;

  Future<void> _saveMyAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      showCustomSnackBar(
          context: context,
          message: AppRecordMessages.formHasErrors,
          type: SnackBarType.warning);
      return;
    }

    final name = _nameController.text;
    final username = _usernameController.text;

    print('Guardando: Nombre: $name, Usuario: $username');
  }

  @override
  void initState() {
    super.initState();

    final session = ref.read(odooSessionNotifierProvider).session;
    _nameController = TextEditingController(text: session?.partnerName ?? '');
    _usernameController = TextEditingController(text: session?.userName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTitles.myAccount),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(goBackLocation);
              }
            }
          )
      ),
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _MyAccountForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  usernameController: _usernameController,
                  onSave: _saveMyAccount
                )
            ),
          )
      )
    );
  }
}

class _MyAccountForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final VoidCallback onSave;

  const _MyAccountForm({
    required this.formKey,
    required this.nameController,
    required this.usernameController,
    required this.onSave
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.account_circle_outlined,
            color: colors.primary,
            size: 80),

          const SizedBox(height: 40),

          CustomTextFormField(
            label: AppFormLabels.partnerName,
            controller: nameController,
            isRequired: true,
            validator: (value) => FormValidators.validateRequired(value)
          ),

          const SizedBox(height: 20),

          CustomTextFormField(
            label: AppFormLabels.username,
            controller: usernameController,
            isRequired: true,
            validator: (value) => FormValidators.validateRequired(value)),

          const SizedBox(height: 40),

          FilledButton.tonalIcon(
            icon: const Icon(Icons.save_rounded),
            label: const Text(AppButtons.save),
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}