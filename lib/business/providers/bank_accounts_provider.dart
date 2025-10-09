import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class BankAccountState {
  final List<BankAccount> bankAccounts;
  final bool isLoading;
  final String? errorMessage;

  BankAccountState({
    this.bankAccounts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BankAccountState copyWith({
    List<BankAccount>? bankAccounts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BankAccountState(
        bankAccounts: bankAccounts ?? this.bankAccounts,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage
    );
  }
}


class BankAccountNotifier extends StateNotifier<BankAccountState> {

  final Ref _ref;

  BankAccountNotifier(this._ref) : super(BankAccountState());

  OdooService _getService() {
    final odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (!odooSessionState.isAuthenticated) {
      throw OdooException(AppNetworkMessages.errorNoConection);
    }

    return odooService;
  }

  Future<void> _fetchBankAccounts() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      final odooService = _getService();
      final bankAccount = await odooService.getBankAccounts();
      state = state.copyWith(
          bankAccounts: bankAccount,
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

  Future<void> loadBankAccounts() async {
    if (state.bankAccounts.isNotEmpty) return;
    await _fetchBankAccounts();
  }

  Future<void> refreshBankAccounts() async {
    await _fetchBankAccounts();
  }

}


final bankAccountProvider = StateNotifierProvider<BankAccountNotifier, BankAccountState>((ref) {

  return BankAccountNotifier(ref);
});
