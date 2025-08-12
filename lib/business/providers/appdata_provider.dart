import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/domain/entities/app_data.dart';
import 'package:yo_te_pago/business/domain/repositories/iappdata_repository.dart';
import 'package:yo_te_pago/infrastructure/repositories/appdata_repository.dart';


typedef AppDataCallback = Future<List<AppData>> Function();


class AppDataNotifier extends StateNotifier<List<AppData>> {

  bool isLoading = false;
  AppDataCallback fetchAllAppDatas;
  final IAppDataRepository appDataRepository;

  AppDataNotifier({
    required this.fetchAllAppDatas,
    required this.appDataRepository
  }) : super( [] );

  Future<void> loadAppDatas() async {
    if (isLoading) {
      return;
    }
    isLoading = true;
    try {
      final result = await fetchAllAppDatas();
      state = result;
    } catch (e, st) {
      throw Exception('Error al cargar AppDatas');
    } finally {
      isLoading = false;
    }
  }

  Future<AppData?> getAppDataByKey(String key) async {
    if (isLoading) {
      return null;
    }
    isLoading = true;
    AppData? result;
    try {
      result = await appDataRepository.getByKey(key);
    } catch (e, st) {
      throw Exception('Error al obtener AppData por clave');
    } finally {
      isLoading = false;
    }

    return result;
  }

}


final appDataProvider = StateNotifierProvider<AppDataNotifier, List<AppData>>((ref) {

  final appDataRepository = ref.watch(appDataRepositoryProvider);
  final fetchAllAppDatas = appDataRepository.getAll;
  final notifier = AppDataNotifier(
    fetchAllAppDatas: fetchAllAppDatas,
    appDataRepository: appDataRepository
  );

  return notifier;
});