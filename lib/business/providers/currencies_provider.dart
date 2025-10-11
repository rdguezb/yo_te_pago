import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class CurrencyState {
  final List<Currency> currencies;
  final bool isLoading;
  final String? errorMessage;
  final bool lastUpdateSuccess;

  CurrencyState({
    this.currencies = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdateSuccess = false
  });

  CurrencyState copyWith({
    List<Currency>? currencies,
    bool? isLoading,
    String? errorMessage,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return CurrencyState(
      currencies: currencies ?? this.currencies,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}


class CurrencyNotifier extends StateNotifier<CurrencyState> {

  final Ref _ref;
  final OdooService _odooService;


  CurrencyNotifier(this._ref, this._odooService) : super(CurrencyState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }
    return true;
  }

  Future<void> _fetchCurrencies() async {
    if (state.currencies.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    try {
      final currencies = await _odooService.getAvailableCurrencies();
      state = state.copyWith(currencies: currencies, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> loadCurrencies() async {
    if (!_isSessionValid()) return;
    if (state.currencies.isNotEmpty) return;
    await _fetchCurrencies();
  }

  Future<void> refreshCurrencies() async {
    if (!_isSessionValid()) return;
    await _fetchCurrencies();
  }

}


final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return CurrencyNotifier(ref, odooService);
});
