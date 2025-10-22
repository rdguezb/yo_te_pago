import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/role.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';

class RolesState {

  final List<Role> roles;
  final bool isLoading;
  final String? errorMessage;

  RolesState({
    this.roles = const [],
    this.isLoading = false,
    this.errorMessage
  });


  RolesState copyWith({
    List<Role>? roles,
    bool? isLoading,
    String? errorMessage
  }) {

    return RolesState(
        roles: roles ?? this.roles,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage
    );
  }
}

class RolesNotifier extends StateNotifier<RolesState> {

  final Ref _ref;
  final OdooService _odooService;

  RolesNotifier(this._ref, this._odooService) : super(RolesState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }
    return true;
  }

  Future<void> _fetchRoles() async {
    if (state.roles.isEmpty) {
      state = state.copyWith(isLoading: true);
    } else {
      state = state.copyWith(errorMessage: null);
    }

    try {
      final roles = await _odooService.getRoles();
      state = state.copyWith(roles: roles, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al cargar los roles.');
    }
  }

  Future<void> loadRoles() async {
    if (!_isSessionValid()) return;
    if (state.roles.isNotEmpty) return;
    await _fetchRoles();
  }

  Future<void> refresh() async {
    if (!_isSessionValid()) return;
    await _fetchRoles();
  }

}

final rolesProvider = StateNotifierProvider<RolesNotifier, RolesState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return RolesNotifier(ref, odooService);
});
