import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yo_te_pago/business/config/constants/app_network_states.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
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
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}


class DeliveryNotifier extends StateNotifier<DeliveryState> {

  final Ref _ref;

  DeliveryNotifier(this._ref) : super(DeliveryState());

  Future<void> loadDeliveries() async {
    if (state.isLoading) {
      return;
    }

    final OdooService? odooService = _ref.read(odooServiceProvider);
    final odooSessionState = _ref.read(odooSessionNotifierProvider);

    if (odooService == null || !odooSessionState.isAuthenticated) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppNetworkMessages.errorNoConection,
      );
      return;
    }
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);

    try {
      final List<User> deliveries = await odooService.getDeliveries();
      state = state.copyWith(
        deliveries: deliveries,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage.isNotEmpty
              ? errorMessage
              : 'Error de red desconocido'
      );
    }
  }

  Future<void> refreshRates() async {
    state = state.copyWith(
        isLoading: true,
        errorMessage: null);
    await loadDeliveries();
  }

}


final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {

  return DeliveryNotifier(ref);
});
