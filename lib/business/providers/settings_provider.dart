import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yo_te_pago/business/config/constants/app_network_states.dart';

import 'package:yo_te_pago/business/domain/entities/company.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class SettingsState {
  final Company? company;
  final bool isLoading;
  final String? errorMessage;
  final bool lastUpdateSuccess;

  SettingsState({
    this.company = null,
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdateSuccess = false
  });

  SettingsState copyWith({
    Company? company,
    bool? isLoading,
    String? errorMessage,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {
    return SettingsState(
        company: company ?? this.company,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {

  final Ref _ref;
  final OdooService _odooService;

  SettingsNotifier(this._ref, this._odooService) : super(SettingsState()) {
    _initializeState();
  }

  void _initializeState() {
    final session = _ref.read(odooSessionNotifierProvider).session;
    if (session != null && session.allowedCompanies.isNotEmpty) {
      try {
        final initialCompany = session.allowedCompanies.firstWhere((company) => company.id == session.companyId);
        state = state.copyWith(company: initialCompany);
      } catch (e) {
        state = state.copyWith(errorMessage: 'No se pudo encontrar la compañía activa en la sesión.');
      }
    }
  }

  String? _validateSession() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      return AppNetworkMessages.errorNoConection;
    }
    return null;
  }

  Future<void> loadParameters() async {
    final sessionError = _validateSession();
    if (sessionError != null) {
      state = state.copyWith(errorMessage: sessionError);
      return;
    }

    if (state.isLoading || state.company == null) return;

    state = state.copyWith(
        isLoading: true,
        clearError: true,
        lastUpdateSuccess: false);

    try {
      final companyBase = state.company!;
      final params = await _odooService.getParameters();

      final updatedCompany = companyBase.copyWith(
        hoursKeeps: params['hours_keeps'] as int?,
      );

      state = state.copyWith(
          company: updatedCompany,
          isLoading: false);

    } on OdooException catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> updateParameters(Company updatedCompany) async {
    final sessionError = _validateSession();
    if (sessionError != null) {
      state = state.copyWith(errorMessage: sessionError);
      return;
    }

    if (state.isLoading) return;

    state = state.copyWith(
        isLoading: true,
        clearError: true,
        lastUpdateSuccess: false);

    try {
      final success = await _odooService.updateParameters(updatedCompany);

      if (success) {
        state = state.copyWith(
            company: updatedCompany,
            isLoading: false,
            lastUpdateSuccess: true);
      } else {
        state = state.copyWith(
            isLoading: false,
            errorMessage: 'La actualización falló en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ocurrió un error inesperado.');
    }
  }

}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return SettingsNotifier(ref, odooService);
});