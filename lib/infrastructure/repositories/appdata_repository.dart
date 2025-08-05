import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'package:yo_te_pago/business/config/constants/api_const.dart';
import 'package:yo_te_pago/business/domain/entities/app_data.dart';
import 'package:yo_te_pago/business/domain/repositories/iappdata_repository.dart';
import 'package:yo_te_pago/business/exceptions/local_storage_exceptions.dart';
import 'package:yo_te_pago/infrastructure/models/pocos/app_data_poco.dart';
import 'package:yo_te_pago/infrastructure/repositories/base_repository.dart';


class AppDataRepository extends BaseRepository<AppData, AppDataPoco> implements IAppDataRepository {

  @override
  Future<IsarCollection<AppDataPoco>> getPocoCollection() async {
    final isar = await db;
    return isar.appDataPocos;
  }

  @override
  Future<AppData?> getByKey(String key) async {
    try {
      IsarCollection<AppDataPoco> collection = await getPocoCollection();
      final result = await collection
          .filter()
          .keyNameEqualTo(key)
          .findFirst();

      if (result == null) {
        return null;
      }

      return toModel(result);
    } on IsarError catch (e, stackTrace) {
      throw LocalStorageException.databaseError(
        message: 'Failed to get item by key',
        innerException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw LocalStorageException(
        message: 'Unexpected error getting item by key',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> hasApiKey() async {
    try {
      final apiData = await getByKey(ApiConfig.keyUser);

      return apiData != null && apiData.valueStr.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  AppData toModel(AppDataPoco poco) {

    return AppData(
      id: poco.id,
      keyName: poco.keyName,
      valueStr: poco.valueStr,
      valueType: poco.valueType
    );
  }

  @override
  AppDataPoco toPoco(AppData model) {

    return AppDataPoco(
      id: model.id ?? Isar.autoIncrement,
      keyName: model.keyName,
      valueStr: model.valueStr,
      valueType: model.valueType
    );
  }

}


final appDataRepositoryProvider = Provider<IAppDataRepository>((ref) {

  return AppDataRepository();
});