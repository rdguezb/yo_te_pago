import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/api_const.dart';
import 'package:yo_te_pago/business/config/constants/app_auth_states.dart';
import 'package:yo_te_pago/business/domain/entities/app_data.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/domain/repositories/iappdata_repository.dart';
import 'package:yo_te_pago/infrastructure/models/odoo_auth_result.dart';
import 'package:yo_te_pago/infrastructure/repositories/appdata_repository.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';


class OdooSessionState {

  final OdooAuth? session;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  OdooSessionState({
    this.session,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  OdooSessionState copyWith({
    OdooAuth? session,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {

    return OdooSessionState(
        session: session ?? this.session,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage
    );
  }

}

class OdooSessionNotifier extends StateNotifier<OdooSessionState> {

  final IAppDataRepository _appDataRepository;
  OdooService? _currentOdooService;

  OdooSessionNotifier(this._appDataRepository) : super(OdooSessionState(isLoading: true)) {
    _initializeSession();
  }

  OdooService? get odooService => _currentOdooService;

  Future<void> _initializeSession() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _performAuthentication(
      isInitial: true,
      noCredentialsError: AppAuthMessages.errorNoCredentialsFound,
      authFailedError: AppAuthMessages.errorFailedToRestoreSession,
      unexpectedError: 'Error al restablecer sesión',
    );
  }

  Future<bool> _performAuthentication({
    required bool isInitial,
    required String noCredentialsError,
    required String authFailedError,
    required String unexpectedError,
  }) async {
    try {
      final userData = await _appDataRepository.getByKey(ApiConfig.keyUser);
      final passwordData = await _appDataRepository.getByKey(ApiConfig.keyPass);

      if (userData == null || passwordData == null || userData.valueStr.isEmpty || passwordData.valueStr.isEmpty) {
        state = state.copyWith(isAuthenticated: false, isLoading: false, errorMessage: noCredentialsError);
        return false;
      }

      final OdooService odooServiceInstance = OdooService();
      final bool authSuccess = await odooServiceInstance.authenticate(
        userData.valueStr,
        passwordData.valueStr,
      );

      if (authSuccess) {
        final OdooAuth sessionInfo = odooServiceInstance.odooSessionInfo;
        _currentOdooService = odooServiceInstance;
        state = state.copyWith(
          session: sessionInfo,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: authFailedError,
        );
        return false;
      }
    } catch (e) {
      _currentOdooService = null;
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: unexpectedError,
      );
      return false;
    }
  }

  Future<void> login() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _performAuthentication(
      isInitial: false,
      noCredentialsError: AppAuthMessages.errorNoCredentialsFound,
      authFailedError: AppAuthMessages.errorFailedToLogin,
      unexpectedError: 'Error al iniciar sesión',
    );
  }

  Future<void> logout() async {
    if (_currentOdooService != null) {
      await _currentOdooService!.logout();
    }
    _currentOdooService = null;
    state = OdooSessionState(
        isLoading: false,
        isAuthenticated: false,
        session: null);
  }

  Future<void> updateLocalSession(User user) async {
    if (state.session == null) return;

    if (user.id == state.session!.user.id) {
      return;
    }

    final newSession = state.session!.copyWith(
      user: user,
    );

    try {
      final userToSave = AppData(
        keyName: ApiConfig.keyUser,
        valueStr: user.login,
        valueType: 'string');

      await _appDataRepository.edit(userToSave);

      state = state.copyWith(
        session: newSession,
        isLoading: false,
        errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al guardar la sesión local: $e');
    }
  }

  @override
  void dispose() {
    if (_currentOdooService != null && state.isAuthenticated) {
      _currentOdooService!.logout().catchError((e) {
        print('OdooService: Error durante el cierre de sesión en dispose: \$e');
      });
    }
    _currentOdooService = null;
    super.dispose();
  }

}

final odooSessionNotifierProvider = StateNotifierProvider<OdooSessionNotifier, OdooSessionState>((ref) {
  final appDataRepository = ref.watch(appDataRepositoryProvider);

  return OdooSessionNotifier(appDataRepository);
});

final odooServiceProvider = Provider<OdooService>((ref) {
  final odooSessionState = ref.watch(odooSessionNotifierProvider);
  final odooSessionNotifier = ref.read(odooSessionNotifierProvider.notifier);

  if (!odooSessionState.isAuthenticated || odooSessionNotifier.odooService == null) {
    throw Exception(AppAuthMessages.errorNoSessionOrProcess);
  }

  return odooSessionNotifier.odooService!;
});
