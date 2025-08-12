import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/validation_messages.dart';
import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class BalanceState {
  final List<Balance> balances;
  final bool isLoading;
  final String? errorMessage;

  BalanceState({
    this.balances = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BalanceState copyWith({
    List<Balance>? balances,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BalanceState(
      balances: balances ?? this.balances,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}


class BalanceNotifier extends StateNotifier<BalanceState> {

  final Ref _ref;

  BalanceNotifier(this._ref) : super(BalanceState());

  Future<void> loadBalances() async {
    if (state.isLoading) {
      return;
    }

    final OdooService? odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (odooService == null || !odooSessionState.isAuthenticated) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: AppStates.noOdooConectionforBalances
      );
      return;
    }

    state = state.copyWith(
        isLoading: true,
        errorMessage: null);

    try {
      final List<Balance> balances = await odooService.getBalances();
      state = state.copyWith(
        balances: balances,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al cargar balances'
      );
    }
  }

  Future<void> refreshBalances() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    await loadBalances();
  }

}

final balanceProvider = StateNotifierProvider<BalanceNotifier, BalanceState>((ref) {

  return BalanceNotifier(ref);
});
