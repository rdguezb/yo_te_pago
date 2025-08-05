import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';


class AuthNotifier extends ChangeNotifier {

  bool _isLoggedIn = false;
  bool _isInitialized = false;

  AuthNotifier();

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  void updateAuthState(OdooSessionState odooState) {
    bool newLoginStatus = odooState.isAuthenticated;
    bool newInitializedStatus = !odooState.isLoading;

    if (_isLoggedIn != newLoginStatus || _isInitialized != newInitializedStatus) {
      _isLoggedIn = newLoginStatus;
      _isInitialized = newInitializedStatus;
      notifyListeners();
    }
  }

}


final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {

  final authNotifier = AuthNotifier();

  ref.listen<OdooSessionState>(odooSessionNotifierProvider, (previous, next) {
      authNotifier.updateAuthState(next);
    },
    fireImmediately: true,
  );

  return authNotifier;
});