import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/role.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/business/providers/roles_provider.dart';
import 'package:yo_te_pago/business/providers/users_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';

class UserFormView extends ConsumerStatefulWidget {

  static const String name = AppRoutes.userCreate;

  final User? user;

  const UserFormView({super.key, this.user});

  @override
  ConsumerState<UserFormView> createState() => _UserFormViewState();

}

class _UserFormViewState extends ConsumerState<UserFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final bool _isEditing;
  String? _selectedRoleId;

  @override
  void initState() {
    super.initState();

    _isEditing = widget.user != null;
    if (_isEditing) {
      _nameController.text = widget.user!.name;
      _loginController.text = widget.user!.login;
      _emailController.text = widget.user!.email ?? '';
      _selectedRoleId = widget.user!.roleId.toString();
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(usersProvider).users.isEmpty) {
        ref.read(usersProvider.notifier).loadNextPage();
      }
      ref.read(rolesProvider.notifier).loadRoles();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _loginController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userState = ref.watch(usersProvider);
    final rolesState = ref.watch(rolesProvider);

    ref.listen(usersProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        showCustomSnackBar(
            scaffoldMessenger: scaffoldMessenger,
            message: next.errorMessage!,
            type: SnackBarType.error);
      }
      if (next.lastUpdateSuccess && previous?.lastUpdateSuccess == false) {
        ref.invalidate(odooSessionNotifierProvider);

        showCustomSnackBar(
            scaffoldMessenger: scaffoldMessenger,
            message: AppMessages.operationSuccess,
            type: SnackBarType.success);
        if (context.canPop()) context.pop();
      }
    });

    return Scaffold(
        appBar: AppBar(
            title: Text(_isEditing ? AppTitles.userEdit : AppTitles.userCreate),
            centerTitle: true),
        body: SafeArea(
            child: (rolesState.isLoading && rolesState.roles.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _UserForm(
                      formKey: _formKey,
                      nameController: _nameController,
                      usernameController: _loginController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isSaving: userState.isLoading,
                      isEditing: _isEditing,
                      roles: rolesState.roles,
                      selectedRoleId: _selectedRoleId,
                      onRoleChanged: (value) {
                        setState(() {
                          _selectedRoleId = value;
                        });
                      },
                      onSave: _saveUser
                  )
        )
    );
  }

  Future<void> _saveUser() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.formHasErrors,
          type: SnackBarType.warning);

      return;
    }

    if (_selectedRoleId == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Por favor, selecciona un rol.',
          type: SnackBarType.warning);
      return;
    }

    if (_isEditing) {
      final updatedUser = widget.user!.copyWith(
          name: _nameController.text,
          login: _loginController.text,
          email: _emailController.text,
          roleId: int.parse(_selectedRoleId!)
      );
      ref.read(usersProvider.notifier).updateUser(updatedUser);
    } else {
      final userData = {
        'name': _nameController.text,
        'login': _loginController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role_id': int.parse(_selectedRoleId!),
      };
      ref.read(usersProvider.notifier).createUser(userData);
    }
  }

}

class _UserForm extends StatelessWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSave;
  final bool isSaving;
  final bool isEditing;
  final List<Role> roles;
  final String? selectedRoleId;
  final ValueChanged<String?> onRoleChanged;

  const _UserForm({
    required this.formKey,
    required this.nameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.isSaving,
    required this.isEditing,
    required this.roles,
    this.selectedRoleId,
    required this.onRoleChanged,
    required this.onSave});

  @override
  Widget build(BuildContext context) {
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

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedRoleId,
                onChanged: onRoleChanged,
                items: roles.map((role) {
                  return DropdownMenuItem(value: role.id.toString(), child: Text(role.name));
                }).toList(),
                decoration: const InputDecoration(
                  labelText: AppFormLabels.role,
                  border: OutlineInputBorder()
                ),
                validator: (value) => value == null ? 'Por favor, selecciona un rol' : null
              ),

              const SizedBox(height: 20),

              if (!isEditing) ...[
                CustomTextFormField(
                  label: AppFormLabels.password,
                  controller: passwordController,
                  isObscure: true,
                  isRequired: !isEditing,
                  validator: (value) {
                    if (isEditing) return null;
                    return FormValidators.validatePassword(value);
                  }
                ),

                const SizedBox(height: 20),

                CustomTextFormField(
                  label: AppFormLabels.confirmPassword,
                  isObscure: true,
                  isRequired: !isEditing,
                  validator: (value) {
                    if (isEditing) return null;
                    return FormValidators.validateConfirmPassword(value, passwordController.text);
                  }
                )
              ],

              const SizedBox(height: 40),

              FilledButton.tonalIcon(
                  icon: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: const Text(AppButtons.save),
                  onPressed: isSaving ? null : onSave
              )
            ]
          )
        )
    );
  }
}
