import 'package:collection/collection.dart';
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
        super(AppDataState()) {
    loadAppDatas();
  }

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

  AppData? getAppDataByKey(String key) {
    try {
      return state.appDatas.firstWhereOrNull((data) => data.keyName == key);
    } catch (e) {
      return null;
    }
  }

  Future<void> addAppData(AppData appData) async {
    state = state.copyWith(isLoading: true);
    try {
      final newData = await _appDataRepository.add(appData);

      if (newData != null) {
        final newList = [...state.appDatas, newData];
        state = state.copyWith(
            appDatas: newList,
            isLoading: false,
            errorMessage: null);
      } else {
        state = state.copyWith(
            isLoading: false,
            errorMessage: 'El repositorio no devolvió el objeto creado.');
      }
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al añadir AppData: $e');
    }
  }

  Future<void> editAppData(AppData appData) async {
    state = state.copyWith(isLoading: true);
    try {
      await _appDataRepository.edit(appData);

      final index = state.appDatas.indexWhere((d) => d.id == appData.id);
      if (index != -1) {
        final newList = List<AppData>.from(state.appDatas);
        newList[index] = appData;
        state = state.copyWith(appDatas: newList, isLoading: false, errorMessage: null);
      } else {
        state = state.copyWith(
            isLoading: false,
            errorMessage: 'Intentando editar un AppData que no existe en el estado.');
      }
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al editar AppData: $e');
    }
  }

}


final appDataProvider = StateNotifierProvider<AppDataNotifier, AppDataState>((ref) {
  final appDataRepository = ref.watch(appDataRepositoryProvider);
  
  return AppDataNotifier(appDataRepository: appDataRepository);
});
