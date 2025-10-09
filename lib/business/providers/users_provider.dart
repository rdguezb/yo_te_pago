import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yo_te_pago/business/config/constants/app_network_states.dart';

import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';

class UsersState {
  final List<User> users;
  final bool isLoading;
  final String? errorMessage;

  UsersState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  UsersState copyWith({
    List<User>? users,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UsersState(
        users: users ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {

  final Ref _ref;

  UsersNotifier(this._ref) : super(UsersState());

  OdooService _getService() {
    final odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (!odooSessionState.isAuthenticated) {
      throw OdooException(AppNetworkMessages.errorNoConection);
    }

    return odooService;
  }

  Future<void> _fetchUsers() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      final odooService = _getService();
      final users = await odooService.getUsers();
      state = state.copyWith(
          users: users,
          isLoading: false,
          errorMessage: null
      );
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

  Future<void> loadUsers() async {
    if (state.users.isNotEmpty) return;
    await _fetchUsers();
  }

  Future<void> refreshUsers() async {
    await _fetchUsers();
  }

  void updateUserInList(User user) {
    final index = state.users.indexWhere((d) => d.id == user.id);
    if (index != -1) {
      final updatedList = List<User>.from(state.users);
      updatedList[index] = user;
      state = state.copyWith(users: updatedList);
    }
  }

}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {

  return UsersNotifier(ref);
});
