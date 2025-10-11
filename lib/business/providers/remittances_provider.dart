import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';

class RemittanceState {
  final List<Remittance> remittances;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final bool lastUpdateSuccess;

  RemittanceState({
    this.remittances = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.lastUpdateSuccess = false
  });

  List<Remittance> get filteredRemittances => searchQuery.isEmpty
      ? remittances
      : remittances
          .where((r) =>
              r.customer.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();

  RemittanceState copyWith({
    List<Remittance>? remittances,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return RemittanceState(
      remittances: remittances ?? this.remittances,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}

class RemittanceNotifier extends StateNotifier<RemittanceState> {

  final Ref _ref;
  final OdooService _odooService;

  RemittanceNotifier(this._ref, this._odooService) : super(RemittanceState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }
    return true;
  }

  Future<void> _fetchRemittances() async {
    if (state.remittances.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    try {
      final remittances = await _odooService.getRemittances();
      state = state.copyWith(remittances: remittances, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> _updateRemittanceState(int remittanceId, String action) async {
    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);

    try {
      bool success = false;

      if (action == 'confirm') {
        success = await _odooService.confirmRemittance(remittanceId);
      } else if (action == 'pay') {
        success = await _odooService.payRemittance(remittanceId);
      }

      if (success) {
        final updatedList = List<Remittance>.from(state.remittances);
        final index = updatedList.indexWhere((r) => r.id == remittanceId);

        if (index != -1) {
          final remittance = updatedList[index];
          final newState = (action == 'confirm') ? 'confirmed' : 'paid';

          updatedList[index] = remittance.copyWith(state: newState);
        }

        state = state.copyWith(isLoading: false, remittances: updatedList, lastUpdateSuccess: true);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> loadRemittances() async {
    if (!_isSessionValid()) return;
    if (state.remittances.isNotEmpty) return;
    await _fetchRemittances();
  }

  Future<void> addRemittance(Remittance remittance) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final newRemittance = await _odooService.addRemittance(remittance);

      final updatedList = [newRemittance, ...state.remittances];

      state = state.copyWith(isLoading: false, lastUpdateSuccess: true, remittances: updatedList);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ocurrió un error inesperado al agregar.');
    }
  }

  Future<void> editRemittance(Remittance remittance) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final success = await _odooService.editRemittance(remittance);

      if (success) {
        final updatedList = List<Remittance>.from(state.remittances);
        final index = updatedList.indexWhere((r) => r.id == remittance.id);

        if (index != -1) {
          updatedList[index] = remittance;
        }

        state = state.copyWith(isLoading: false, remittances: updatedList, lastUpdateSuccess: true);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al editar.');
    }
  }

  Future<void> confirmRemittance(int remittanceId) async {
    if (!_isSessionValid()) return;
    await _updateRemittanceState(remittanceId, 'confirm');
  }

  Future<void> payRemittance(int remittanceId) async {
    if (!_isSessionValid()) return;
    await _updateRemittanceState(remittanceId, 'pay');
  }

  Future<void> deleteRemittance(int remittanceId) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final success = await _odooService.deleteRemittance(remittanceId);

      if (success) {
        final updatedList = state.remittances.where((r) => r.id != remittanceId).toList();
        state = state.copyWith(isLoading: false, lastUpdateSuccess: true, remittances: updatedList);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ocurrió un error inesperado al eliminar.');
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refreshRemittances() async {
    if (!_isSessionValid()) return;
    await _fetchRemittances();
  }
}

final remittanceProvider = StateNotifierProvider<RemittanceNotifier, RemittanceState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return RemittanceNotifier(ref, odooService);
});
