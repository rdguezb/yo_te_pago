import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';

class ProfileState {

  final bool isLoading;
  final String? errorMessage;
  final bool lastUpdateSuccess;

  ProfileState({
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdateSuccess = false
  });

  ProfileState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {

  final Ref _ref;
  final OdooService _odooService;

  ProfileNotifier(this._ref, this._odooService) : super(ProfileState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }
    return true;
  }

  Future<void> editProfile(User user) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);

    try {
      final success = await _odooService.editUser(user);

      if (success) {
        state = state.copyWith(isLoading: false, lastUpdateSuccess: true);

        _ref.invalidate(odooSessionNotifierProvider);

      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al editar el perfil.');
    }
  }

  void resetState() {
    state = state.copyWith(
      lastUpdateSuccess: false,
      errorMessage: null,
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return ProfileNotifier(ref, odooService);
});
