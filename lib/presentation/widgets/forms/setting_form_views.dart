import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/providers/settings_provider.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class SettingsFormView extends ConsumerStatefulWidget {

  static const String name = AppRoutes.settings;

  const SettingsFormView({super.key});

  @override
  ConsumerState<SettingsFormView> createState() => _SettingsFormViewState();

}

class _SettingsFormViewState extends ConsumerState<SettingsFormView> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _hoursController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).loadParameters();
    });
  }

  @override
  void dispose() {
    _hoursController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = ref.watch(settingsProvider.select((state) => state.company));
    final isLoading = ref.watch(settingsProvider.select((s) => s.isLoading));

    if (company != null && company.hoursKeeps > 0 && _hoursController.text.isEmpty) {
      _hoursController.text = company.hoursKeeps.toString();
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    ref.listen(settingsProvider, (previous, next) {
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
            title: Text(AppTitles.companyParameters),
            centerTitle: true
        ),
        body: SafeArea(
            child: (isLoading && _hoursController.text.isEmpty)
                ? const Center(child: CircularProgressIndicator())
                : _SettingsForm(
                      formKey: _formKey,
                      hoursController: _hoursController,
                      isSaving: isLoading,
                      onSave: _saveParameters
                  )
        )
    );
  }

  Future<void> _saveParameters() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.formHasErrors,
          type: SnackBarType.warning);

      return;
    }

    final companyBase = ref.read(settingsProvider).company;
    if (companyBase == null) {
      showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: 'No se pudo encontrar la compañía activa.',
          type: SnackBarType.warning);
      return;
    }

    final hours = int.tryParse(_hoursController.text) ?? 0;
    final companyToSave = companyBase.copyWith(hoursKeeps: hours);

    await ref.read(settingsProvider.notifier).updateParameters(companyToSave);
  }

}

class _SettingsForm extends ConsumerWidget {

  final GlobalKey<FormState> formKey;
  final TextEditingController hoursController;
  final VoidCallback onSave;
  final bool isSaving;

  const _SettingsForm({
    required this.formKey,
    required this.hoursController,
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
                      Icons.lock_outline_rounded,
                      color: colors.primary,
                      size: 80
                  ),

                  const SizedBox(height: 40),

                  CustomTextFormField(
                    label: AppFormLabels.hours,
                    controller: hoursController,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    validator: (value) => FormValidators.validateInt(value)),

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
