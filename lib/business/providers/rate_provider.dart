import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class RateState {
  final List<Rate> rates;
  final bool isLoading;
  final String? errorMessage;

  RateState({
    this.rates = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RateState copyWith({
    List<Rate>? rates,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RateState(
      rates: rates ?? this.rates,
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
        errorMessage: AppNetworkMessages.errorNoConection);

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
        errorMessage: null);
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        rates: [],
        isLoading: false,
        errorMessage: errorMessage.isNotEmpty
            ? errorMessage
            : 'Error de red desconocido'
      );
    }
  }

  Future<void> refreshRates() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    await loadRates();
  }

}


final rateProvider = StateNotifierProvider<RateNotifier, RateState>((ref) {

  return RateNotifier(ref);
});
