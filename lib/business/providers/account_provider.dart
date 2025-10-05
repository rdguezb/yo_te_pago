import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/account.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class AccountState {
  final List<Account> accounts;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  AccountState({
    this.accounts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = ''
  });

  List<Account> get filteredAccounts => searchQuery.isEmpty
      ? accounts
      : accounts
      .where((r) =>
        (r.partnerName ?? '').toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();

  AccountState copyWith({
    List<Account>? accounts,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery
  }) {
    return AccountState(
        accounts: accounts ?? this.accounts,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        searchQuery: searchQuery ?? this.searchQuery);
  }
}


class AccountNotifier extends StateNotifier<AccountState> {

  final Ref _ref;

  AccountNotifier(this._ref) : super(AccountState());

  OdooService _getService() {
    final odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (!odooSessionState.isAuthenticated) {
      throw OdooException(AppNetworkMessages.errorNoConection);
    }

    return odooService;
  }

  Future<void> _fetchAccounts() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      final odooService = _getService();
      final accounts = await odooService.getAccounts();
      state = state.copyWith(
          accounts: accounts,
          isLoading: false,
          errorMessage: null);
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

  Future<void> loadAccounts() async {
    if (state.accounts.isNotEmpty) return;
    await _fetchAccounts();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refreshAccounts() async {
    await _fetchAccounts();
  }
  
  Future<void> deleteAccount(Account account) async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      bool success = false;
      final odooService = _getService();
      success = await odooService.deleteAccount(account);

      if (success) {
        final updatedList = state.accounts
            .where((a) => a.id != account.id)
            .toList();
        state = state.copyWith(
            isLoading: false,
            accounts: updatedList);
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
          errorMessage: 'Ocurrió un error inesperado al desasociar.');
    }
  }

  Future<void> linkAccount(Account account) async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      bool success = false;
      final odooService = _getService();
      success = await odooService.linkAccount(account);

      if (success) {
        await _fetchAccounts();
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
          errorMessage: 'Ocurrió un error inesperado al asociar.');
    }
  }

}


final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {

  return AccountNotifier(ref);
});
