import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/bank.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class BankState {
  final List<Bank> banks;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool lastUpdateSuccess;

  BankState({
    this.banks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.lastUpdateSuccess = false
  });

  List<Bank> get filteredBanks => searchQuery.isEmpty
      ? banks
      : banks
      .where((b) => (b.name).toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();

  BankState copyWith({
    List<Bank>? banks,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return BankState(
        banks: banks ?? this.banks,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        searchQuery: searchQuery ?? this.searchQuery,
        lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}

class BankNotifier extends StateNotifier<BankState> {

  final Ref _ref;
  final OdooService _odooService;

  BankNotifier(this._ref, this._odooService) : super(BankState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }
    return true;
  }

  Future<void> _fetchBanks() async {
    if (state.banks.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    try {
      final banks = await _odooService.getBanks();
      state = state.copyWith(banks: banks, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al cargar los bancos.');
    }
  }

  Future<void> loadBanks() async {
    if (!_isSessionValid()) return;
    if (state.banks.isNotEmpty) return;
    await _fetchBanks();
  }

  Future<void> refreshBanks() async {
    if (!_isSessionValid()) return;
    await _fetchBanks();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> addBank(Bank bank) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);

    try {
      final newBank = await _odooService.addBank(bank);

      final updatedList = [newBank, ...state.banks];

      state = state.copyWith(isLoading: false, lastUpdateSuccess: true, banks: updatedList);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ocurrió un error inesperado al agregar el banco.');
    }
  }

  Future<void> updateBank(Bank bank) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);

    try {
      final success = await _odooService.updateBank(bank);

      if (success) {
        final updatedList = List<Bank>.from(state.banks);
        final index = updatedList.indexWhere((b) => b.id == bank.id);

        if (index != -1) {
          updatedList[index] = bank;
        }

        state = state.copyWith(isLoading: false, banks: updatedList, lastUpdateSuccess: true);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al editar el banco.');
    }
  }

}

final bankProvider = StateNotifierProvider<BankNotifier, BankState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return BankNotifier(ref, odooService);
});