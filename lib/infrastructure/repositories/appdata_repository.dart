import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:yo_te_pago/business/config/constants/api_const.dart';
import 'package:yo_te_pago/business/domain/entities/app_data.dart';
import 'package:yo_te_pago/business/domain/repositories/iappdata_repository.dart';
import 'package:yo_te_pago/business/exceptions/local_storage_exceptions.dart';
import 'package:yo_te_pago/infrastructure/models/pocos/app_data_poco.dart';
import 'package:yo_te_pago/infrastructure/repositories/base_repository.dart';


class AppDataRepository extends BaseRepository<AppData, AppDataPoco> implements IAppDataRepository {

  @override
  String get tableName => 'app_data';

  @override
  String get createTableSQL => '''
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyName TEXT UNIQUE,
      valueStr TEXT,
      valueType TEXT
    )
  ''';


  @override
  Future<AppData?> getByKey(String key) async {
    try {
      final database = await db;
      final List<Map<String, dynamic>> result = await database.query(
        tableName,
        where: 'keyName = ?',
        whereArgs: [key],
      );
      if (result.isEmpty) {
        return null;
      }
      final poco = AppDataPoco.fromMap(result.first);

      return toModel(poco);
    } on DatabaseException catch (e, stackTrace) {
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
      keyName: poco.keyName,
      valueStr: poco.valueStr,
      valueType: poco.valueType
    );
  }

  @override
  AppDataPoco toPoco(AppData model) {

    return AppDataPoco(
      keyName: model.keyName,
      valueStr: model.valueStr,
      valueType: model.valueType
    );
  }

}


final appDataRepositoryProvider = Provider<IAppDataRepository>((ref) {

  return AppDataRepository();
});