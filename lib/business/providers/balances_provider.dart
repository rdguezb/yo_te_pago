import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class BalanceState {
  final List<Balance> balances;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool lastUpdateSuccess;

  BalanceState({
    this.balances = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.lastUpdateSuccess = false
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
    String? searchQuery,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return BalanceState(
        balances: balances ?? this.balances,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        searchQuery: searchQuery ?? this.searchQuery,
        lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}


class BalanceNotifier extends StateNotifier<BalanceState> {

  final Ref _ref;
  final OdooService _odooService;

  BalanceNotifier(this._ref, this._odooService) : super(BalanceState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }

    return true;
  }

  Future<void> _fetchBalances() async {
    if (state.balances.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    try {
      final balances = await _odooService.getBalances();
      state = state.copyWith(balances: balances, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> loadBalances() async {
    if (!_isSessionValid()) return;
    if (state.balances.isNotEmpty) return;
    await _fetchBalances();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refreshBalances() async {
    if (!_isSessionValid()) return;
    await _fetchBalances();
  }

  Future<void> updateBalance(int currencyId, int deliveryId, double amount, String action) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final success = await _odooService.updateBalance(currencyId, deliveryId, amount, action);
      if (success) {
        state = state.copyWith(isLoading: false, lastUpdateSuccess: true);
        await _fetchBalances();
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al actualizar.');
    }
  }

}

final balanceProvider = StateNotifierProvider<BalanceNotifier, BalanceState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return BalanceNotifier(ref, odooService);
});
