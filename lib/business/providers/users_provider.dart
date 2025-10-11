import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';

class UsersState {
  final List<User> users;
  final bool isLoading;
  final String? errorMessage;
  final bool lastUpdateSuccess;

  UsersState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdateSuccess = false
  });

  UsersState copyWith({
    List<User>? users,
    bool? isLoading,
    String? errorMessage,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return UsersState(
        users: users ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {

  final Ref _ref;
  final OdooService _odooService;

  UsersNotifier(this._ref, this._odooService) : super(UsersState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }
    return true;
  }

  Future<void> _fetchUsers() async {
    if (state.users.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    try {
      final users = await _odooService.getUsers();
      state = state.copyWith(users: users, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> loadUsers() async {
    if (!_isSessionValid()) return;
    if (state.users.isNotEmpty) return;
    await _fetchUsers();
  }

  Future<void> refreshUsers() async {
    if (!_isSessionValid()) return;
    await _fetchUsers();
  }

  // Future<void> createUser(User user) async {
  //   if (!_isSessionValid()) return;
  //
  //   state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
  //   try {
  //     final newUser = await _odooService.createUser(user);
  //
  //     final updatedList = [newUser, ...state.users];
  //
  //     state = state.copyWith(isLoading: false, lastUpdateSuccess: true, users: updatedList);
  //   } on OdooException catch (e) {
  //     state = state.copyWith(isLoading: false, errorMessage: e.message);
  //   } catch (e) {
  //     state = state.copyWith(
  //         isLoading: false, errorMessage: 'Ocurrió un error inesperado al crear el usuario.');
  //   }
  // }
  //

  Future<void> updateUser(User user) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final success = await _odooService.editUser(user);

      if (success) {
        final updatedList = List<User>.from(state.users);
        final index = updatedList.indexWhere((u) => u.id == user.id);

        if (index != -1) {
          updatedList[index] = user;
        }

        state = state.copyWith(isLoading: false, lastUpdateSuccess: true, users: updatedList);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al actualizar el usuario.');
    }
  }

  // Future<void> deleteUser(int userId) async {
  //   if (!_isSessionValid()) return;
  //
  //   state = state.copyWith(isLoading: true, clearError: true, lastUpdateSuccess: false);
  //   try {
  //     final success = await _odooService.deleteUser(userId);
  //
  //     if (success) {
  //       final updatedList = state.users.where((u) => u.id != userId).toList();
  //
  //       state = state.copyWith(isLoading: false, lastUpdateSuccess: true, users: updatedList);
  //     } else {
  //       state = state.copyWith(
  //           isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
  //     }
  //   } on OdooException catch (e) {
  //     state = state.copyWith(isLoading: false, errorMessage: e.message);
  //   } catch (e) {
  //     state = state.copyWith(
  //         isLoading: false, errorMessage: 'Ocurrió un error inesperado al eliminar el usuario.');
  //   }
  // }
  //
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return UsersNotifier(ref, odooService);
});


// void updateUserInList(User user) {
//   final updatedList = List<User>.from(state.users);
//   final index = updatedList.indexWhere((d) => d.id == user.id);
//   if (index != -1) {
//     updatedList[index] = user;
//     state = state.copyWith(isLoading: false, lastUpdateSuccess: true, users: updatedList);
//   }
// }
