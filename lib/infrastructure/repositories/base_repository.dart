import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:yo_te_pago/business/domain/repositories/ibase_repository.dart';
import 'package:yo_te_pago/business/exceptions/local_storage_exceptions.dart';
import 'package:yo_te_pago/infrastructure/models/pocos/app_data_poco.dart';


abstract class BaseRepository<T, TPoco> extends IBaseRepository<T> {
  late Future<Database> db;

  T toModel(TPoco poco);
  TPoco toPoco(T model);

  BaseRepository() {
    db = openDB();
  }

  String get tableName;
  String get createTableSQL;

  Future<String> _getDbPath() async {
    final dir = await getApplicationDocumentsDirectory();

    return join(dir.path, 'yotepago_database.db');
  }

  Future<Database> openDB() async {
    try {
      final path = await _getDbPath();

      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(createTableSQL);
        },
      );
    } catch (e, stackTrace) {
      throw LocalStorageException(
        message: 'Unexpected error when opening database',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<T>> getAll() async {
    try {
      final database = await db;
      final List<Map<String, dynamic>> result = await database.query(tableName);

      return result.map((map) => toModel(AppDataPoco.fromMap(map) as TPoco)).toList();
    } on DatabaseException catch (e, stackTrace) {
      throw LocalStorageException.databaseError(
        message: 'Failed to get all items',
        innerException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw LocalStorageException(
        message: 'Unexpected error getting all items',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<T?> getById(int id) async {
    try {
      final database = await db;
      final List<Map<String, dynamic>> result = await database.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        return null;
      }

      // Obtiene el primer resultado y lo convierte a Model.
      return toModel(AppDataPoco.fromMap(result.first) as TPoco);
    } on DatabaseException catch (e, stackTrace) {
      throw LocalStorageException.databaseError(
        message: 'Failed to get item by id',
        innerException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw LocalStorageException(
        message: 'Unexpected error getting item by id',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<T?> add(T item) async {
    try {
      final database = await db;
      final poco = toPoco(item) as AppDataPoco;
      final int id = await database.insert(
        tableName,
        poco.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return getById(id);
    } on DatabaseException catch (e, stackTrace) {
      throw LocalStorageException.databaseError(
        message: 'Failed to add item',
        innerException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw LocalStorageException(
        message: 'Unexpected error adding item',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> edit(T item) async {
    try {
      final database = await db;
      final poco = toPoco(item) as AppDataPoco;
      await database.update(
        tableName,
        poco.toMap(),
        where: 'id = ?',
        whereArgs: [poco.id],
      );
    } on DatabaseException catch (e, stackTrace) {
      throw LocalStorageException.databaseError(
        message: 'Failed to edit item',
        innerException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw LocalStorageException(
        message: 'Unexpected error editing item',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      final database = await db;
      await database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e, stackTrace) {
      throw LocalStorageException.databaseError(
        message: 'Failed to delete item',
        innerException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw LocalStorageException(
        message: 'Unexpected error deleting item',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      final database = await db;
      await database.delete(tableName);
    } on DatabaseException catch (e, stackTrace) {
      throw LocalStorageException.databaseError(
        message: 'Failed to delete all items',
        innerException: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      throw LocalStorageException(
        message: 'Unexpected error deleting all items',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }

}