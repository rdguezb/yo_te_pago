import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
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
      errorMessage: errorMessage
    );
  }
}


class CurrencyNotifier extends StateNotifier<CurrencyState> {

  final Ref _ref;

  CurrencyNotifier(this._ref) : super(CurrencyState());

  OdooService _getService() {
    final odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (!odooSessionState.isAuthenticated) {
      throw OdooException(AppNetworkMessages.errorNoConection);
    }

    return odooService;
  }

  Future<void> _fetchCurrencies() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      final odooService = _getService();
      final currencies = await odooService.getAvailableCurrencies();
      state = state.copyWith(
          currencies: currencies,
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

  Future<void> loadCurrencies() async {
    if (state.currencies.isNotEmpty) return;
    await _fetchCurrencies();
  }

  Future<void> refreshCurrencies() async {
    await _fetchCurrencies();
  }

}


final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {

  return CurrencyNotifier(ref);
});
