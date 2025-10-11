import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class RateState {
  final List<Rate> rates;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool lastUpdateSuccess;

  RateState({
    this.rates = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.lastUpdateSuccess = false
  });

  List<Rate> get filteredRates => searchQuery.isEmpty
      ? rates
      : rates
      .where((r) =>
        (r.partnerName ?? '').toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();


  RateState copyWith({
    List<Rate>? rates,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return RateState(
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}


class RateNotifier extends StateNotifier<RateState> {

  final Ref _ref;
  final OdooService _odooService;

  RateNotifier(this._ref, this._odooService) : super(RateState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }
    return true;
  }

  Future<void> _fetchRates() async {
    if (state.rates.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    try {
      final rates = await _odooService.getRates();
      state = state.copyWith(rates: rates, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> loadRates() async {
    if (!_isSessionValid()) return;
    if (state.rates.isNotEmpty) return;
    await _fetchRates();
  }

  Future<void> addRate(Rate rate) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final newRate = await _odooService.addRate(rate);

      final updatedList = [newRate, ...state.rates];

      state = state.copyWith(isLoading: false, lastUpdateSuccess: true, rates: updatedList);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al agregar.');
    }
  }

  Future<void> changeRate(Rate rate) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final success = await _odooService.changeRate(rate);

      if (success) {
        final updatedList = List<Rate>.from(state.rates);
        final index = updatedList.indexWhere((r) => r.id == rate.id);

        if (index != -1) {
          updatedList[index] = rate;
        }

        state = state.copyWith(isLoading: false, lastUpdateSuccess: true, rates: updatedList);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Ocurrió un error inesperado al editar.');
    }
  }

  Future<void> deleteRate(int rateId) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final success = await _odooService.deleteRate(rateId);

      if (success) {
        final updatedList = state.rates.where((r) => r.id != rateId).toList();
        state = state.copyWith(isLoading: false, lastUpdateSuccess: true, rates: updatedList);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Ocurrió un error inesperado al eliminar.');
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refreshRates() async {
    if (!_isSessionValid()) return;
    await _fetchRates();
  }

}


final rateProvider = StateNotifierProvider<RateNotifier, RateState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return RateNotifier(ref, odooService);
});
