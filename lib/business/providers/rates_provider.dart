import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class RateState {
  final List<Rate> rates;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  RateState({
    this.rates = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = ''
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
    String? searchQuery
  }) {
    return RateState(
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery);
  }
}


class RateNotifier extends StateNotifier<RateState> {

  final Ref _ref;

  RateNotifier(this._ref) : super(RateState());

  OdooService _getService() {
    final odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (!odooSessionState.isAuthenticated) {
      throw OdooException(AppNetworkMessages.errorNoConection);
    }

    return odooService;
  }

  Future<void> _fetchRates() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      final odooService = _getService();
      final rates = await odooService.getRates();
      state = state.copyWith(
          rates: rates,
          isLoading: false,
          errorMessage: null
      );
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

  Future<void> loadRates() async {
    if (state.rates.isNotEmpty) return;
    await _fetchRates();
  }

  Future<void> addRate(Rate rate) async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      final odooService = _getService();
      final newRate = await odooService.addRate(rate);

      state = state.copyWith(
          isLoading: false,
          rates: [newRate, ...state.rates]);
    } on OdooException catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ocurrió un error inesperado al agregar.');
    }
  }

  Future<void> changeRate(Rate rate) async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      bool success = false;
      final odooService = _getService();
      success = await odooService.changeRate(rate);

      if (success) {
        final index = state.rates
            .indexWhere((r) => r.id == rate.id);
        if (index != -1) {
          final updatedList = List<Rate>.from(state.rates);
          updatedList[index] = rate;
          state = state.copyWith(
              isLoading: false,
              rates: updatedList);
        } else {
          await _fetchRates();
        }
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
          errorMessage: 'Ocurrió un error inesperado al editar.');
    }
  }

  Future<void> deleteRate(int rateId) async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      bool success = false;
      final odooService = _getService();
      success = await odooService.deleteRate(rateId);

      if (success) {
        final updatedList = state.rates
            .where((r) => r.id != rateId).toList();
        state = state.copyWith(
            isLoading: false,
            rates: updatedList);
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
          errorMessage: 'Ocurrió un error inesperado al eliminar.');

    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refreshRates() async {
    await _fetchRates();
  }

}


final rateProvider = StateNotifierProvider<RateNotifier, RateState>((ref) {

  return RateNotifier(ref);
});
