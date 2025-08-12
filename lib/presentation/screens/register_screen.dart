import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/api_const.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/constants/validation_messages.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/app_data.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/repositories/appdata_repository.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class RegisterScreen extends StatelessWidget {

  static const name = 'register-screen';

  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text(AppTitles.registration),
            centerTitle: true
        ),
        body: const SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: _RegisterForm()
              ),
            )
        )
    );
  }

}

class _RegisterForm extends ConsumerStatefulWidget {

  const _RegisterForm();

  @override
  ConsumerState<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<bool> _registerUser() async {
    if (!mounted) {
      return false;
    }
    try {
      final repository = ref.read(appDataRepositoryProvider);
      await repository.add(AppData(
        keyName: ApiConfig.keyUser,
        valueStr: _usernameController.text.trim(),
        valueType: 'string'
      ));
      await repository.add(AppData(
        keyName: ApiConfig.keyPass,
        valueStr: _passwordController.text.trim(),
        valueType: 'string'
      ));

      if (!mounted) {
        return false;
      }
      showCustomSnackBar(
        context: context,
        message: AppStates.registerSuccess,
        type: SnackBarType.success,
      );

      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      showCustomSnackBar(
        context: context,
        message: AppStates.registerFailure,
        type: SnackBarType.error
      );

      return false;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Form(
        key: _formKey,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                  Icons.person_outline_sharp,
                  size: 60
              ),

              const SizedBox(height: 30),

              CustomTextFormField(
                label: AppFormLabels.username,
                controller: _usernameController,
                isRequired: true,
                validator: (value) => FormValidators.validateRequired(value)),

              const SizedBox(height: 20),

              CustomTextFormField(
                label: AppFormLabels.password,
                controller: _passwordController,
                isRequired: true,
                isObscure: true,
                validator: (value) => FormValidators.validateRequired(value)),

              const SizedBox(height: 20),

              FilledButton.tonalIcon(
                onPressed: () async {
                  final form = _formKey.currentState;
                  if (form == null || !form.validate()) {
                    return;
                  }
                  try {
                    final success = await _registerUser();
                    if (success && mounted) {
                      await ref.read(odooSessionNotifierProvider.notifier).login();
                    }
                  } catch (e) {
                    if (!mounted) {
                      return;
                    }
                    if (!context.mounted) {
                      return;
                    }
                    showCustomSnackBar(
                      context: context,
                      message: AppStates.registerFailure,
                      type: SnackBarType.error,
                    );
                  }
                },
                icon: const Icon(Icons.how_to_reg_outlined),
                label: const Text(AppTitles.registration),
              )
            ]));
  }

}
