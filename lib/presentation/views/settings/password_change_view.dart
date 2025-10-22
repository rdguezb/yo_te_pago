import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/providers/profile_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class PasswordChangeView extends ConsumerStatefulWidget {

  static const name = AppRoutes.password;

  const PasswordChangeView({super.key});

  @override
  ConsumerState<PasswordChangeView> createState() => _PasswordChangeViewState();
}

class _PasswordChangeViewState extends ConsumerState<PasswordChangeView> {

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    ref.listen(profileProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: next.errorMessage!,
          type: SnackBarType.error,
        );
      }
      if (next.lastUpdateSuccess && previous?.lastUpdateSuccess == false) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Contraseña actualizada con éxito.',
          type: SnackBarType.success,
        );
        if (context.canPop()) context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Contraseña'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextFormField(
                label: AppFormLabels.currentPassword,
                controller: _currentPasswordController,
                isObscure: true,
                isRequired: true,
                validator: FormValidators.validateRequired),

              const SizedBox(height: 20),

              CustomTextFormField(
                label: AppFormLabels.newPassword,
                controller: _newPasswordController,
                isObscure: true,
                isRequired: true,
                validator: FormValidators.validatePassword),

              const SizedBox(height: 20),

              CustomTextFormField(
                label: AppFormLabels.confirmPassword,
                controller: _confirmPasswordController,
                isObscure: true,
                isRequired: true,
                validator: (value) => FormValidators.validateConfirmPassword(
                  value,
                  _newPasswordController.text)),

              const SizedBox(height: 40),

              FilledButton.tonalIcon(
                icon: profileState.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: const Text(AppButtons.save),
                onPressed: profileState.isLoading ? null : _submit)
            ]
          )
        )
      )
    );
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
        scaffoldMessenger: ScaffoldMessenger.of(context),
        message: AppMessages.formHasErrors,
        type: SnackBarType.warning,
      );
      return;
    }

    ref.read(profileProvider.notifier).changeOwnPassword(
      oldPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
  }


}
