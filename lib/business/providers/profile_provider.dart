import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/business/providers/users_provider.dart';

class ProfileNotifier {
  final Ref _ref;

  ProfileNotifier(this._ref);

  Future<void> editProfile(User user) async {
    final odooService = _ref.read(odooServiceProvider);
    final success = await odooService.editMyAccount(user);

    if (!success) {
      throw Exception('La operación no se pudo completar en el servidor.');
    }

    await _ref.read(odooSessionNotifierProvider.notifier).updateLocalSession(
        user);

    final userListState = _ref.read(usersProvider);
    if (userListState.users.isNotEmpty) {
      _ref.read(usersProvider.notifier).updateUserInList(user);
    }
  }
}

final profileProvider = Provider<ProfileNotifier>((ref) {
  return ProfileNotifier(ref);
});