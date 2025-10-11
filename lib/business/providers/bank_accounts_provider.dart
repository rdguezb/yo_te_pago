import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class BankAccountState {
  final List<BankAccount> bankAccounts;
  final bool isLoading;
  final String? errorMessage;
  final bool lastUpdateSuccess;

  BankAccountState({
    this.bankAccounts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdateSuccess = false
  });

  BankAccountState copyWith({
    List<BankAccount>? bankAccounts,
    bool? isLoading,
    String? errorMessage,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return BankAccountState(
        bankAccounts: bankAccounts ?? this.bankAccounts,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}


class BankAccountNotifier extends StateNotifier<BankAccountState> {

  final Ref _ref;
  final OdooService _odooService;

  BankAccountNotifier(this._ref, this._odooService) : super(BankAccountState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }
    return true;
  }

  Future<void> _fetchBankAccounts() async {
    if (state.bankAccounts.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    try {
      final bankAccount = await _odooService.getBankAccounts();
      state = state.copyWith(bankAccounts: bankAccount, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> loadBankAccounts() async {
    if (!_isSessionValid()) return;
    if (state.bankAccounts.isNotEmpty) return;
    await _fetchBankAccounts();
  }

  Future<void> refreshBankAccounts() async {
    if (!_isSessionValid()) return;
    await _fetchBankAccounts();
  }

}


final bankAccountProvider = StateNotifierProvider<BankAccountNotifier, BankAccountState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return BankAccountNotifier(ref, odooService);
});
