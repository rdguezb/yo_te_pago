import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class BalanceState {
  final List<Balance> balances;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  BalanceState({
    this.balances = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = ''
  });

  List<Balance> get filteredBalances => searchQuery.isEmpty
      ? balances
      : balances
      .where((r) =>
        r.partnerName.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();

  BalanceState copyWith({
    List<Balance>? balances,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery
  }) {
    return BalanceState(
        balances: balances ?? this.balances,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        searchQuery: searchQuery ?? this.searchQuery);
  }
}


class BalanceNotifier extends StateNotifier<BalanceState> {

  final Ref _ref;

  BalanceNotifier(this._ref) : super(BalanceState());

  OdooService _getService() {
    final odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (!odooSessionState.isAuthenticated) {
      throw OdooException(AppNetworkMessages.errorNoConection);
    }

    return odooService;
  }

  Future<void> _fetchBalances() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      final odooService = _getService();
      final balances = await odooService.getBalances();
      state = state.copyWith(
          balances: balances,
          isLoading: false,
          errorMessage: null);
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

  Future<void> loadBalances() async {
    if (state.balances.isNotEmpty) return;
    await _fetchBalances();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refreshBalances() async {
    await _fetchBalances();
  }

  Future<void> updateBalance(int currencyId, int deliveryId, double amount, String action) async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      bool success = false;
      final odooService = _getService();
      success = await odooService.updateBalance(currencyId, deliveryId, amount, action);
      if (success) {
        _fetchBalances();
      } else {
        state = state.copyWith(
            isLoading: false,
            errorMessage: "La operación no se pudo completar en el servidor.");
      }
    } on OdooException catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ocurrió un error inesperado al actualizar.');
    }
  }

}


final balanceProvider = StateNotifierProvider<BalanceNotifier, BalanceState>((ref) {

  return BalanceNotifier(ref);
});
