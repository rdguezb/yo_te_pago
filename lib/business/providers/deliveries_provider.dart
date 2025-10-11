import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';

class DeliveryState {
  final List<User> deliveries;
  final bool isLoading;
  final String? errorMessage;
  final bool lastUpdateSuccess;

  DeliveryState({
    this.deliveries = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdateSuccess = false
  });

  DeliveryState copyWith({
    List<User>? deliveries,
    bool? isLoading,
    String? errorMessage,
    bool? lastUpdateSuccess,
    bool clearError = false
  }) {

    return DeliveryState(
      deliveries: deliveries ?? this.deliveries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastUpdateSuccess: lastUpdateSuccess ?? this.lastUpdateSuccess
    );
  }
}


class DeliveryNotifier extends StateNotifier<DeliveryState> {

  final Ref _ref;
  final OdooService _odooService;


  DeliveryNotifier(this._ref, this._odooService) : super(DeliveryState());

  bool _isSessionValid() {
    if (!_ref.read(odooSessionNotifierProvider).isAuthenticated) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tu sesión ha expirado.');
      return false;
    }
    return true;
  }

  Future<void> _fetchDeliveries() async {
    if (state.deliveries.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(clearError: true);
    }

    try {
      final deliveries = await _odooService.getDeliveries();
      state = state.copyWith(deliveries: deliveries, isLoading: false);
    } on OdooException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Ocurrió un error inesperado.');
    }
  }

  Future<void> loadDeliveries() async {
    if (!_isSessionValid()) return;
    if (state.deliveries.isNotEmpty) return;
    await _fetchDeliveries();
  }

  Future<void> refreshDeliveries() async {
    if (!_isSessionValid()) return;
    await _fetchDeliveries();
  }

}


final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {
  final odooService = ref.watch(odooServiceProvider);

  return DeliveryNotifier(ref, odooService);
});
