import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/infrastructure/services/odoo_services.dart';

class DeliveryState {
  final List<User> deliveries;
  final bool isLoading;
  final String? errorMessage;

  DeliveryState({
    this.deliveries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DeliveryState copyWith({
    List<User>? deliveries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DeliveryState(
      deliveries: deliveries ?? this.deliveries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage
    );
  }
}


class DeliveryNotifier extends StateNotifier<DeliveryState> {

  final Ref _ref;

  DeliveryNotifier(this._ref) : super(DeliveryState());

  OdooService _getService() {
    final odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (!odooSessionState.isAuthenticated) {
      throw OdooException(AppNetworkMessages.errorNoConection);
    }

    return odooService;
  }

  Future<void> _fetchDeliveries() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    try {
      final odooService = _getService();
      final deliveries = await odooService.getDeliveries();
      state = state.copyWith(
          deliveries: deliveries,
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

  Future<void> loadDeliveries() async {
    if (state.deliveries.isNotEmpty) return;
    await _fetchDeliveries();
  }

  Future<void> refreshDeliveries() async {
    await _fetchDeliveries();
  }

}


final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {

  return DeliveryNotifier(ref);
});
