import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/validation_messages.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class CurrencyState {
  final List<Currency> currencies;
  final bool isLoading;
  final String? errorMessage;

  CurrencyState({
    this.currencies = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CurrencyState copyWith({
    List<Currency>? currencies,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CurrencyState(
      currencies: currencies ?? this.currencies,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}


class CurrencyNotifier extends StateNotifier<CurrencyState> {

  final Ref _ref;

  CurrencyNotifier(this._ref) : super(CurrencyState());

  Future<void> loadCurrencies() async {
    if (state.isLoading) {
      return;
    }

    final OdooService? odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (odooService == null || !odooSessionState.isAuthenticated) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppStates.noOdooConectionforCurrencies,
      );
      return;
    }
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);

    try {
      final List<Currency> currencies = await odooService.getCurrencies();
      state = state.copyWith(
        currencies: currencies,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar monedas: ${e.toString()}'
      );
    }
  }

  Future<void> refreshCurrencies() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    await loadCurrencies();
  }

}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {

  return CurrencyNotifier(ref);
});
