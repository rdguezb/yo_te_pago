import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class BankAccountState {
  final List<BankAccount> accounts;
  final List<BankAccount> allowedAccounts;
  final bool isLoading;
  final String? errorMessage;

  BankAccountState({
    this.accounts = const [],
    this.allowedAccounts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BankAccountState copyWith({
    List<BankAccount>? accounts,
    List<BankAccount>? allowedAccounts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BankAccountState(
      accounts: accounts ?? this.accounts,
      allowedAccounts: allowedAccounts ?? this.allowedAccounts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}


class BankAccountNotifier extends StateNotifier<BankAccountState> {

  final Ref _ref;

  BankAccountNotifier(this._ref) : super(BankAccountState());

  Future<void> loadAccounts() async {
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
        errorMessage: null,
        accounts: [],
        allowedAccounts: []
    );

    try {
      final List<BankAccount> accounts = await odooService.getBankAccounts();

      state = state.copyWith(
        accounts: accounts,
        allowedAccounts: [],
        isLoading: false,
        errorMessage: null);
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
          accounts: [],
          allowedAccounts: [],
          isLoading: false,
          errorMessage: errorMessage.isNotEmpty
              ? errorMessage
              : 'Error de red desconocido'
      );
    }
  }

  Future<void> loadAllowedAccounts() async {
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
      final List<BankAccount> accounts = await odooService.getAllowedBankAccounts();
      state = state.copyWith(
          accounts: [],
          allowedAccounts: accounts,
          isLoading: false,
          errorMessage: null);
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
          accounts: [],
          allowedAccounts: [],
          isLoading: false,
          errorMessage: errorMessage.isNotEmpty
              ? errorMessage
              : 'Error de red desconocido'
      );
    }
  }

  Future<void> refreshAccounts() async {
    state = state.copyWith(
        accounts: [],
        allowedAccounts: [],
        isLoading: true,
        errorMessage: null);
    await loadAccounts();
  }

  Future<void> refreshAllowedAccounts() async {
    state = state.copyWith(
        accounts: [],
        allowedAccounts: [],
        isLoading: true,
        errorMessage: null);
    await loadAllowedAccounts();
  }

}


final accountProvider = StateNotifierProvider<BankAccountNotifier, BankAccountState>((ref) {

  return BankAccountNotifier(ref);
});
