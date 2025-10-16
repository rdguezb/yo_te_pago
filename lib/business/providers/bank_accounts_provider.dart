import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class BankAccountState {
  final List<BankAccount> bankAccounts;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String searchQuery;
  final bool lastUpdateSuccess;

  BankAccountState({
    this.bankAccounts = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.searchQuery = '',
    this.lastUpdateSuccess = false
  });

  List<BankAccount> get filteredBankAccounts {
    if (searchQuery.isEmpty) return bankAccounts;
    final query = searchQuery.toLowerCase();
    return bankAccounts
        .where((a) => a.name.toLowerCase().contains(query)).toList();
  }

  BankAccountState copyWith({
    List<BankAccount>? bankAccounts,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    String? searchQuery,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return BankAccountState(
        bankAccounts: bankAccounts ?? this.bankAccounts,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        searchQuery: searchQuery ?? this.searchQuery,
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

  Future<void> loadBankAccounts() async {
    if (state.bankAccounts.isNotEmpty || state.isLoading) return;
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final bankAccounts = await _odooService.getBankAccounts();
      state = state.copyWith(bankAccounts: bankAccounts, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al cargar las cuentas.');
    }
  }

  Future<void> refreshBankAccounts() async {
    if (state.isRefreshing || state.isLoading) return;
    if (!_isSessionValid()) return;

    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final bankAccounts = await _odooService.getBankAccounts();
      state = state.copyWith(bankAccounts: bankAccounts, isRefreshing: false);
    } on OdooException catch (e) {
      state = state.copyWith(isRefreshing: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isRefreshing: false, errorMessage: 'Ocurrió un error inesperado al recargar.');
    }
  }

  Future<void> _performAndUpdate(Future<void> Function() operation) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isRefreshing: true, clearError: true, lastUpdateSuccess: false);

    try {
      await operation();

      state = state.copyWith(isRefreshing: false, lastUpdateSuccess: true);
    } on OdooException catch (e) {
      state = state.copyWith(isRefreshing: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isRefreshing: false, errorMessage: 'Ocurrió un error inesperado durante la operación.');
    }
  }

  Future<void> addBankAccount(BankAccount bankAccount) async {
    await _performAndUpdate(() async {
      final newBankAccount = await _odooService.addBankAccount(bankAccount);

      state = state.copyWith(bankAccounts: [newBankAccount, ...state.bankAccounts]);
    });
  }

  Future<void> updateBankAccount(BankAccount bankAccount) async {
    await _performAndUpdate(() async {
      final success = await _odooService.updateBankAccount(bankAccount);
      if (success) {
        final index = state.bankAccounts.indexWhere((b) => b.id == bankAccount.id);
        if (index != -1) {
          final updatedList = List<BankAccount>.from(state.bankAccounts);
          updatedList[index] = bankAccount;
          state = state.copyWith(bankAccounts: updatedList);
        }
      } else {
        throw OdooException('La operación no se pudo completar en el servidor.');
      }
    });
  }

  Future<void> deleteBankAccount(int id) async {
    await _performAndUpdate(() async {
      final success = await _odooService.deleteBankAccount(id);
      if (success) {
        final updatedList = state.bankAccounts.where((b) => b.id != id).toList();
        state = state.copyWith(bankAccounts: updatedList);
      } else {
        throw OdooException('La operación no se pudo completar en el servidor.');
      }
    });
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

}


final bankAccountProvider = StateNotifierProvider<BankAccountNotifier, BankAccountState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return BankAccountNotifier(ref, odooService);
});
