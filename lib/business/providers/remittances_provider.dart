import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';

class RemittanceState {
  final List<Remittance> remittances;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  RemittanceState({
    this.remittances = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = ''
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
    String? searchQuery
  }) {
    return RemittanceState(
      remittances: remittances ?? this.remittances,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery
    );
  }
}

class RemittanceNotifier extends StateNotifier<RemittanceState> {
  final Ref _ref;

  RemittanceNotifier(this._ref) : super(RemittanceState());

  OdooService _getService() {
    final odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (!odooSessionState.isAuthenticated) {
      throw OdooException(AppNetworkMessages.errorNoConection);
    }

    return odooService;
  }

  Future<void> _fetchRemittances() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final odooService = _getService();
      final remittances = await odooService.getRemittances();
      state = state.copyWith(
          remittances: remittances, isLoading: false, errorMessage: null);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> _updateRemittanceState(int remittanceId, String action) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final remittance =
        state.remittances.firstWhereOrNull((r) => r.id == remittanceId);
    if (remittance == null) {
      state = state.copyWith(
          isLoading: false, errorMessage: "Error: No se encontró la remesa.");
      return;
    }

    try {
      bool success = false;
      final odooService = _getService();

      if (action == 'confirm') {
        success = await odooService.confirmRemittance(remittance);
      } else if (action == 'pay') {
        success = await odooService.payRemittance(remittance);
      }

      if (success) {
        final newState = action == 'confirm' ? 'confirmed' : 'paid';
        final index =
            state.remittances.indexWhere((r) => r.id == remittanceId);
        if (index != -1) {
          final updatedList = List<Remittance>.from(state.remittances);
          updatedList[index] = remittance.copyWith(state: newState);
          state = state.copyWith(
              isLoading: false, remittances: updatedList, errorMessage: null);
        } else {
          await _fetchRemittances();
        }
      } else {
        state = state.copyWith(
            isLoading: false,
            errorMessage: "La operación no se pudo completar en el servidor.");
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> loadRemittances() async {
    if (state.remittances.isNotEmpty) return;
    await _fetchRemittances();
  }

  Future<void> addRemittance(Remittance remittance) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final odooService = _getService();
      final newRemittance = await odooService.addRemittance(remittance);

      state = state.copyWith(
          isLoading: false,
          remittances: [newRemittance, ...state.remittances]);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ocurrió un error inesperado al agregar.');
    }
  }

  Future<void> editRemittance(Remittance remittance) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      bool success = false;
      final odooService = _getService();
      success = await odooService.editRemittance(remittance);

      if (success) {
        final index =
            state.remittances.indexWhere((r) => r.id == remittance.id);
        if (index != -1) {
          final updatedList = List<Remittance>.from(state.remittances);
          updatedList[index] = remittance;
          state = state.copyWith(isLoading: false, remittances: updatedList);
        } else {
          await _fetchRemittances();
        }
      } else {
        state = state.copyWith(
            isLoading: false,
            errorMessage: "La operación no se pudo completar en el servidor.");
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ocurrió un error inesperado al editar.');
    }
  }

  Future<void> confirmRemittance(int remittanceId) async {
    await _updateRemittanceState(remittanceId, 'confirm');
  }

  Future<void> payRemittance(int remittanceId) async {
    await _updateRemittanceState(remittanceId, 'pay');
  }

  Future<void> deleteRemittance(int remittanceId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      bool success = false;
      final odooService = _getService();
      success = await odooService.deleteRemittance(remittanceId);

      if (success) {
        final updatedList =
            state.remittances.where((r) => r.id != remittanceId).toList();
        state =
            state.copyWith(isLoading: false, remittances: updatedList);
      } else {
        state = state.copyWith(
            isLoading: false,
            errorMessage: "La operación no se pudo completar en el servidor.");
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
    await _fetchRemittances();
  }
}

final remittanceProvider =
    StateNotifierProvider<RemittanceNotifier, RemittanceState>((ref) {
  return RemittanceNotifier(ref);
});
