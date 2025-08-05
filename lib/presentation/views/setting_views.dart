import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/api_const.dart';
import 'package:yo_te_pago/business/config/constants/configs.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/config/constants/validation_messages.dart';
import 'package:yo_te_pago/business/config/helpers/form_fields_validators.dart';
import 'package:yo_te_pago/business/domain/entities/app_data.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/repositories/appdata_repository.dart';
import 'package:yo_te_pago/presentation/widgets/input/custom_text_form_fields.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';


class SettingsView extends StatefulWidget {

  const SettingsView( {super.key} );

  @override
  State<SettingsView> createState() => _SettingsViewState();

}


class _SettingsViewState extends State<SettingsView> {

  @override
  Widget build( BuildContext context ) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(AppTitles.settings),
          centerTitle: true
      ),
      body: const SafeArea(
          child: SingleChildScrollView(
            child: Padding(
                padding: EdgeInsets.all(24.0),
                child: _SettingsForm()
            ),
          )
      ),
    );
  }

}


class _SettingsForm extends ConsumerStatefulWidget {

  const _SettingsForm();

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();

}


class _SettingsFormState extends ConsumerState<_SettingsForm> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _partnerController = TextEditingController();
  bool _isInitialLoadDone = false;
  String _user = '';
  String _partner = '';

  Future<void> _loadData() async {
    try {
      final repository = ref.read(appDataRepositoryProvider);
      AppData? userData = await repository.getByKey(ApiConfig.keyUser);
      if (mounted) {
        final odooService = ref.read(odooServiceProvider);
        final partnerName = odooService.partnerName;

        _user = userData?.valueStr ?? '';
        _partner = partnerName;

        setState(() {
          _usernameController.text = _user;
          _partnerController.text = _partner;
        });
      }
    } catch ( e ) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Error al cargar datos: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<bool> _saveData() async {
    if (!mounted) {
      return false;
    }
    try {
      bool isSaved = false;
      final repository = ref.read(appDataRepositoryProvider);
      final odooService = ref.read(odooServiceProvider);
      final username = _usernameController.text.trim();
      final partner = _partnerController.text.trim();

      if (_user != username) {
        isSaved = true;
        AppData userData = AppData(
            keyName: ApiConfig.keyUser,
            valueStr: username,
            valueType: 'string');
        await repository.add(userData);
        await odooService.editUser(username);
      }
      if (_partner != partner) {
        isSaved = true;
        await odooService.editPartner(partner);
      }

      if (isSaved) {
        if (!mounted) {
          return false;
        }
        showCustomSnackBar(
          context: context,
          message: AppStates.registerSuccess,
          type: SnackBarType.success,
        );
      }

      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      showCustomSnackBar(
          context: context,
          message: 'Error: ${e.toString()}',
          type: SnackBarType.error
      );
      return false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialLoadDone && mounted) {
      _loadData();
      _isInitialLoadDone = true;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _partnerController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
                Icons.admin_panel_settings_rounded,
                color: colors.primary,
                size: 60
            ),

            const SizedBox(height: 30),

            CustomTextFormField(
                label: AppFormLabels.username,
                controller: _usernameController,
                isRequired: true,
                validator: (value) => FormValidators.validateRequired(value)
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            CustomTextFormField(
                label: AppFormLabels.name,
                controller: _partnerController,
                isRequired: true,
                validator: (value) => FormValidators.validateRequired(value)
            ),

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
                    context.go(AppConfig.rootPath);
                  }
                } catch (e) {
                  if (!context.mounted) {
                    return;
                  }
                  showCustomSnackBar(
                    context: context,
                    message: 'Error: ${e.toString()}',
                    type: SnackBarType.error,
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text(AppButtons.save),
            )

          ],
        ));
  }

}
