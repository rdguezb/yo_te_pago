import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';

class CurrencyState {

  final List<Currency> currencies;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final bool lastUpdateSuccess;
  final String searchQuery;
  final bool isNextPageLoading;
  final int page;
  final bool noMoreData;

  CurrencyState({
    this.currencies = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.searchQuery = '',
    this.lastUpdateSuccess = false,
    this.isNextPageLoading = false,
    this.page = 0,
    this.noMoreData = false
  });

  List<Currency> get filteredCurrencies {
    if (searchQuery.isEmpty) return currencies;
    final query = searchQuery.toLowerCase();
    return currencies
        .where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  CurrencyState copyWith({
    List<Currency>? currencies,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? lastUpdateSuccess,
    bool? isNextPageLoading,
    int? page,
    bool? noMoreData,
    bool clearError = false
  }) {

    return CurrencyState(
        currencies: currencies ?? this.currencies,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        searchQuery: searchQuery ?? this.searchQuery,
        lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess,
        isNextPageLoading: isNextPageLoading ?? this.isNextPageLoading,
        page: page ?? this.page,
        noMoreData: noMoreData ?? this.noMoreData
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

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isNextPageLoading || state.noMoreData) return;
    if (!_isSessionValid()) return;

    if (state.page == 0) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isNextPageLoading: true, clearError: true);
    }

    try {
      const limit = 20;
      final offset = state.page * limit;

      final newCurrencies = await _odooService.getCurrencies(limit: limit, offset: offset);

      final noMoreData = newCurrencies.length < limit;

      state = state.copyWith(
        currencies: [...state.currencies, ...newCurrencies],
        isLoading: false,
        isNextPageLoading: false,
        page: state.page + 1,
        noMoreData: noMoreData
      );
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, isNextPageLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, isNextPageLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> refresh() async {
    state = CurrencyState();
    await loadNextPage();
  }

  Future<void> toggleCurrencyActive(int currencyId) async {
    if (!_isSessionValid()) return;
    state = state.copyWith(lastUpdateSuccess: false, clearError: true);

    try {
      await _odooService.toggleCurrencyActive(currencyId);
      await refresh();
      state = state.copyWith(lastUpdateSuccess: true);
    } on OdooException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error inesperado al cambiar estado.');
    }
  }

  Future<void> updateCurrencyRate(int currencyId, double newRate) async {
    if (!_isSessionValid()) return;
    state = state.copyWith(lastUpdateSuccess: false, clearError: true);
    try {
      await _odooService.updateCurrencyRate(currencyId, newRate);
      await refresh();
      state = state.copyWith(lastUpdateSuccess: true);
    } on OdooException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error inesperado al actualizar la tasa.');
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return CurrencyNotifier(ref, odooService);
});
