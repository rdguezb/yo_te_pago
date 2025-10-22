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
  final String searchQuery;
  final bool isNextPageLoading;
  final int page;
  final bool noMoreData;

  UsersState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.lastUpdateSuccess = false,
    this.isNextPageLoading = false,
    this.page = 0,
    this.noMoreData = false
  });

  List<User> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    final query = searchQuery.toLowerCase();
    return users
        .where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  UsersState copyWith({
    List<User>? users,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    bool? lastUpdateSuccess,
    bool? isNextPageLoading,
    int? page,
    bool? noMoreData,
    bool clearError = false
  }) {

    return UsersState(
        users: users ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        searchQuery: searchQuery ?? this.searchQuery,
        lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess,
        isNextPageLoading: isNextPageLoading ?? this.isNextPageLoading,
        page: page ?? this.page,
        noMoreData: noMoreData ?? this.noMoreData
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

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isNextPageLoading || state.noMoreData) return;
    if (!_isSessionValid()) return;

    if (state.page == 0) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isNextPageLoading: true, clearError: true);
    }

    try {
      const limit = 20;
      final offset = state.page * limit;

      final newUsers = await _odooService.getUsers(limit: limit, offset: offset);

      final noMoreData = newUsers.length < limit;

      state = state.copyWith(
          users: [...state.users, ...newUsers],
          isLoading: false,
          isNextPageLoading: false,
          page: state.page + 1,
          noMoreData: noMoreData
      );
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, isNextPageLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, isNextPageLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> refresh() async {
    state = UsersState();
    await loadNextPage();
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(
        isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final newUser = await _odooService.createUser(userData);

      final updatedList = [newUser, ...state.users];

      state = state.copyWith(
          isLoading: false, lastUpdateSuccess: true, users: updatedList);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al crear el usuario.');
    }
  }

  Future<void> updateUser(User user) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(
        isLoading: true, clearError: true, lastUpdateSuccess: false);
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

  Future<void> changeUserPassword(int userId, String newPassword) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(
        isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final success = await _odooService.adminSetUserPassword(userId, newPassword);

      if (success) {
        state = state.copyWith(isLoading: false, lastUpdateSuccess: true);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La contraseña no se pudo cambiar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al cambiar la contraseña.');
    }
  }

  Future<void> deleteUser(int userId) async {
    if (!_isSessionValid()) return;

    state = state.copyWith(
        isLoading: true, clearError: true, lastUpdateSuccess: false);
    try {
      final success = await _odooService.deleteUser(userId);

      if (success) {
        final updatedList = state.users.where((u) => u.id != userId).toList();

        state = state.copyWith(
            isLoading: false, lastUpdateSuccess: true, users: updatedList);
      } else {
        state = state.copyWith(
            isLoading: false, errorMessage: 'La operación no se pudo completar en el servidor.');
      }
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado al eliminar el usuario.');
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return UsersNotifier(ref, odooService);
});
