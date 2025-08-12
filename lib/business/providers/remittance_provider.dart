import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/validation_messages.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class RemittanceState {
  final List<Remittance> remittances;
  final bool isLoading;
  final String? errorMessage;

  RemittanceState({
    this.remittances = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RemittanceState copyWith({
    List<Remittance>? remittances,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RemittanceState(
      remittances: remittances ?? this.remittances,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}


class RemittanceNotifier extends StateNotifier<RemittanceState> {

  final Ref _ref;

  RemittanceNotifier(this._ref) : super(RemittanceState());

  Future<void> loadRemittances() async {
    if (state.isLoading) {
      return;
    }

    final OdooService? odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (odooService == null || !odooSessionState.isAuthenticated) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppStates.noOdooConectionforRemittances
      );
      return;
    }

    state = state.copyWith(
        isLoading: true,
        errorMessage: null);

    try {
      final List<Remittance> remittances = await odooService.getRemittances();
      state = state.copyWith(
        remittances: remittances,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar remesas'
      );
    }
  }

  Future<void> refreshRemittances() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    await loadRemittances();
  }

}


final remittanceProvider = StateNotifierProvider<RemittanceNotifier, RemittanceState>((ref) {

  return RemittanceNotifier(ref);
});
