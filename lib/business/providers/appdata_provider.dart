import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/app_data.dart';
import 'package:yo_te_pago/business/domain/repositories/iappdata_repository.dart';
import 'package:yo_te_pago/infrastructure/repositories/appdata_repository.dart';


class AppDataState {
  final List<AppData> appDatas;
  final bool isLoading;
  final String? errorMessage;

  AppDataState({
    this.appDatas = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AppDataState copyWith({
    List<AppData>? appDatas,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppDataState(
      appDatas: appDatas ?? this.appDatas,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}


class AppDataNotifier extends StateNotifier<AppDataState> {

  final IAppDataRepository _appDataRepository;

  AppDataNotifier({required IAppDataRepository appDataRepository})
      : _appDataRepository = appDataRepository,
        super(AppDataState());

  Future<void> loadAppDatas() async {
    if (state.isLoading) return;

    state = state.copyWith(
        isLoading: true,
        errorMessage: null);

    try {
      final result = await _appDataRepository.getAll();
      state = state.copyWith(
          appDatas: result,
          isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar AppDatas: $e',
      );
    }
  }

  Future<AppData?> getAppDataByKey(String key) async {
    try {
      return await _appDataRepository.getByKey(key);
    } catch (e) {
      print('Error al obtener AppData por clave: $e');
      return null;
    }
  }
  
  Future<void> saveAppData(String key, String value, String valueType) async {
    final appData = AppData(
        keyName: key,
        valueStr: value,
        valueType: valueType);
    await _appDataRepository.add(appData);
  }

}


final appDataProvider = StateNotifierProvider<AppDataNotifier, AppDataState>((ref) {
  final appDataRepository = ref.watch(appDataRepositoryProvider);
  
  return AppDataNotifier(appDataRepository: appDataRepository);
});
