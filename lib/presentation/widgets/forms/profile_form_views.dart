import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_record_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/business/providers/profile_provider.dart';
import 'package:yo_te_pago/presentation/routes/app_router.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class ProfileFormView extends ConsumerStatefulWidget {
  static const String name = 'profile';

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
    _initializeFormData();
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
    final goBackLocation = ref.read(appRouterProvider).namedLocation(AppRoutes.home, pathParameters: {'page': '4'});

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
                })),
        body: SafeArea(
            child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _ProfileForm(
                  formKey: _formKey,
                  nameController: _nameController,
                  usernameController: _loginController,
                  emailController: _emailController,
                  onSave: _saveMyProfile))
        )));
  }

  void _initializeFormData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goBackLocation = ref.read(appRouterProvider).namedLocation(AppRoutes.home, pathParameters: {'page': '4'});

      final session = ref.read(authNotifierProvider).session;

      if (session == null) {
        showCustomSnackBar(
            scaffoldMessenger: scaffoldMessenger,
            message: 'Error: No se encontró el usuario.',
            type: SnackBarType.error);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(goBackLocation);
        }
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
    });
  }

  Future<void> _saveMyProfile() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppRecordMessages.formHasErrors,
          type: SnackBarType.warning);

      return;
    }

    final goBackLocation = ref.read(appRouterProvider).namedLocation(AppRoutes.home, pathParameters: {'page': '4'});
    final sessionNotifier = ref.read(odooSessionNotifierProvider.notifier);

    final name = _nameController.text;
    final username = _loginController.text;
    final email = _emailController.text;

    try {
      User userToSave = _user!.copyWith(name: name, login: username, email: email);
      await ref.read(profileProvider).editProfile(userToSave);
      await sessionNotifier.updateLocalSession(userToSave);

      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppRecordMessages.registerSuccess,
          type: SnackBarType.success);

      if (context.canPop()) {
        context.pop();
      } else {
        context.go(goBackLocation);
      }
    } on OdooException catch (e) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: e.message,
          type: SnackBarType.error);
    } catch (e) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'Ocurrió un error inesperado.',
          type: SnackBarType.error);
    }
  }
}

class _ProfileForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final VoidCallback onSave;

  const _ProfileForm(
      {required this.formKey,
      required this.nameController,
      required this.usernameController,
      required this.emailController,
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
            icon: const Icon(Icons.save_rounded),
            label: const Text(AppButtons.save),
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}
