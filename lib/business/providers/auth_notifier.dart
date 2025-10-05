import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/models/odoo_auth_result.dart';


class AuthNotifier extends ChangeNotifier {

  bool _isLoggedIn = false;
  bool _isInitialized = false;
  OdooAuth? _session;

  AuthNotifier();

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  OdooAuth? get session => _session;

  void updateAuthState(OdooSessionState odooState) {
    bool newLoginStatus = odooState.isAuthenticated;
    bool newInitializedStatus = !odooState.isLoading;
    OdooAuth? newSession = odooState.session;

    if (_isLoggedIn != newLoginStatus || _isInitialized != newInitializedStatus || _session != newSession) {
      _isLoggedIn = newLoginStatus;
      _isInitialized = newInitializedStatus;
      _session = newSession;
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
