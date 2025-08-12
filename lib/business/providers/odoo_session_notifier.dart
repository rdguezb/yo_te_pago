import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/api_const.dart';
import 'package:yo_te_pago/business/config/constants/validation_messages.dart';
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
      errorMessage: errorMessage ?? this.errorMessage,
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

    state = state.copyWith(
        isLoading: true,
        errorMessage: null);

    try {
      final userData = await _appDataRepository.getByKey(ApiConfig.keyUser);
      final passwordData = await _appDataRepository.getByKey(ApiConfig.keyPass);

      if (userData == null || passwordData == null || userData.valueStr.isEmpty || passwordData.valueStr.isEmpty) {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: AppStates.noCredentialsFound,
        );
        return;
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
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: AppStates.failedToRestoreSession,
        );
      }

    } catch (e) {
      _currentOdooService = null;
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: 'Error al restablecer sesión',
      );
    }
  }

  Future<void> login() async {

    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      final userData = await _appDataRepository.getByKey(ApiConfig.keyUser);
      final passwordData = await _appDataRepository.getByKey(ApiConfig.keyPass);

      if (userData == null || passwordData == null || userData.valueStr.isEmpty || passwordData.valueStr.isEmpty) {
        throw Exception(AppStates.noCredentialsConfig);
      }
      final OdooService odooService = OdooService();
      final bool authSuccess = await odooService.authenticate(
        userData.valueStr,
        passwordData.valueStr,
      );

      if (authSuccess) {
        final OdooAuth sessionInfo = odooService.odooSessionInfo;
        _currentOdooService = odooService;
        state = state.copyWith(
          session: sessionInfo,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: AppStates.failedToLogin,
        );
      }

    } catch (e) {
      _currentOdooService = null;
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: 'Error al iniciar sesión',
      );
    }
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

  @override
  void dispose() {
    if (_currentOdooService != null && state.isAuthenticated) {
      _currentOdooService!.logout().then((_) {
      }).catchError((e) {
        throw Exception('OdooService: Error durante el cierre de sesión: $e');
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
    throw Exception(AppStates.noSessionOrProcess);
  }

  return odooSessionNotifier.odooService!;
});