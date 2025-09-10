import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class RateState {
  final List<Rate> rates;
  final List<Rate> currencies;
  final bool isLoading;
  final String? errorMessage;

  RateState({
    this.rates = const [],
    this.currencies = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RateState copyWith({
    List<Rate>? rates,
    List<Rate>? currencies,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RateState(
      rates: rates ?? this.rates,
      currencies: currencies ?? this.currencies,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}


class RateNotifier extends StateNotifier<RateState> {

  final Ref _ref;

  RateNotifier(this._ref) : super(RateState());

  Future<void> loadRates() async {
    if (state.isLoading) {
      return;
    }

    final OdooService? odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (odooService == null || !odooSessionState.isAuthenticated) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppNetworkMessages.errorNoConection,
      );
      return;
    }
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);

    try {
      final List<Rate> rates = await odooService.getRates();
      state = state.copyWith(
        rates: rates,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar tasas'
      );
    }
  }

  Future<void> loadCurrencies() async {
    if (state.isLoading) {
      return;
    }

    final OdooService? odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (odooService == null || !odooSessionState.isAuthenticated) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppNetworkMessages.errorNoConection,
      );
      return;
    }
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);

    try {
      final List<Rate> currencies = await odooService.getAvailableCurrencies();

      state = state.copyWith(
        currencies: currencies,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al cargar monedas'
      );
    }
  }

  Future<void> refreshRates() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    await loadRates();
  }

  Future<void> refreshCurrencies() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    await loadCurrencies();
  }


}


final rateProvider = StateNotifierProvider<RateNotifier, RateState>((ref) {

  return RateNotifier(ref);
});
