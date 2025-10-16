import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class CompanyCurrencyState {
  final List<Currency> currencies;
  final bool isLoading;
  final String? errorMessage;
  final bool lastUpdateSuccess;

  CompanyCurrencyState({
    this.currencies = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdateSuccess = false
  });

  CompanyCurrencyState copyWith({
    List<Currency>? currencies,
    bool? isLoading,
    String? errorMessage,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return CompanyCurrencyState(
      currencies: currencies ?? this.currencies,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}


class CompanyCurrencyNotifier extends StateNotifier<CompanyCurrencyState> {

  final Ref _ref;
  final OdooService _odooService;


  CompanyCurrencyNotifier(this._ref, this._odooService) : super(CompanyCurrencyState());

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
      final currencies = await _odooService.getAllowCurrencies();
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


final companyCurrencyProvider = StateNotifierProvider<CompanyCurrencyNotifier, CompanyCurrencyState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return CompanyCurrencyNotifier(ref, odooService);
});
