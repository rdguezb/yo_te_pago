import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/business/providers/profile_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class ProfileFormView extends ConsumerStatefulWidget {

  static const String name = AppRoutes.profile;

  const ProfileFormView({super.key});

  @override
  ConsumerState<ProfileFormView> createState() => _ProfileFormViewState();

}

class _ProfileFormViewState extends ConsumerState<ProfileFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  User? _user;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFormData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _loginController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final profileState = ref.watch(profileProvider);

    ref.listen(profileProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        showCustomSnackBar(
            scaffoldMessenger: scaffoldMessenger,
            message: next.errorMessage!,
            type: SnackBarType.error
        );
      }
      if (next.lastUpdateSuccess && previous?.lastUpdateSuccess == false) {
        ref.invalidate(odooSessionNotifierProvider);

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
            title: const Text(AppTitles.myProfile),
            centerTitle: true
        ),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _ProfileForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  usernameController: _loginController,
                  emailController: _emailController,
                  isSaving: profileState.isLoading,
                  onSave: _saveMyProfile))
        )));
  }

  void _initializeFormData() {
    if (!mounted) return;
    ref.read(profileProvider.notifier).resetState();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final session = ref.read(authNotifierProvider).session;

    if (session == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Error: No se encontró el usuario.',
          type: SnackBarType.error);
      if (context.canPop()) context.pop();
    } else {
      final user = User(
          id: session.partnerId,
          userId: session.userId,
          name: session.partnerName,
          role: session.role!,
          email: session.email,
          login: session.userName);

      _nameController.text = user.name;
      _loginController.text = user.login;
      _emailController.text = user.email ?? '';
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _saveMyProfile() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.formHasErrors,
          type: SnackBarType.warning);

      return;
    }

    if (_user == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Error: No se ha podido cargar la información del usuario.',
          type: SnackBarType.error);
      return;
    }

    final name = _nameController.text;
    final username = _loginController.text;
    final email = _emailController.text;

    User userToSave = _user!.copyWith(name: name, login: username, email: email);

    await ref.read(profileProvider.notifier).editProfile(userToSave);
  }
}

class _ProfileForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final VoidCallback onSave;
  final bool isSaving;

  const _ProfileForm({
    required this.formKey,
    required this.nameController,
    required this.usernameController,
    required this.emailController,
    required this.isSaving,
    required this.onSave});

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
              validator: (value) => FormValidators.validateRequired(value)),

          const SizedBox(height: 20),

          CustomTextFormField(
              label: AppFormLabels.username,
              controller: usernameController,
              isRequired: true,
              validator: (value) => FormValidators.validateRequired(value)),

          const SizedBox(height: 20),

          CustomTextFormField(
              label: AppFormLabels.email,
              controller: emailController,
              validator: (value) => FormValidators.validateEmail(value)),

          const SizedBox(height: 40),

          FilledButton.tonalIcon(
            icon: isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded),
            label: const Text(AppButtons.save),
            onPressed: isSaving ? null : onSave
          ),
        ],
      ),
    );
  }
}
