import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:yo_te_pago/business/domain/repositories/ibase_repository.dart';
import 'package:yo_te_pago/business/exceptions/local_storage_exceptions.dart';
import 'package:yo_te_pago/infrastructure/models/pocos/app_data_poco.dart';


abstract class BaseRepository<T, TPoco> extends IBaseRepository<T> {
  late Future<Isar> db;

  Future<IsarCollection<TPoco>> getPocoCollection();
  T toModel(TPoco poco);
  TPoco toPoco(T model);

  BaseRepository() {
    db = openDB();
  }

  Future<String> _getDbPath() async {
    final dir = await getApplicationDocumentsDirectory();

    return dir.path;
  }

  Future<Isar> openDB() async {
    try {
      if (Isar.instanceNames.isEmpty) {
        final path = await _getDbPath();

        return await Isar.open(
            [AppDataPocoSchema],
            directory: path,
            inspector: true);
      }

      return Future.value(Isar.getInstance());
    } catch (e, stackTrace) {
      throw LocalStorageException(
        message: 'Unexpected error when open database',
        innerException: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<T>> getAll() async {
    try {
      final collection = await getPocoCollection();
      final result = await collection
          .where()
          .findAll();

      return result.map(toModel).toList();
    } on IsarError catch (e, stackTrace) {
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
      final collection = await getPocoCollection();
      final result = await collection.get(id);
      if (result == null) {
        return null;
      }

      return toModel(result);
    } on IsarError catch (e, stackTrace) {
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
      final isar = await db;
      final collection = await getPocoCollection();
      final result = await isar.writeTxn(() async {
        return await collection.put(toPoco(item));
      });

      return getById(result);
    } on IsarError catch (e, stackTrace) {
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
      final collection = await getPocoCollection();
      final isar = await db;
      await isar.writeTxn(() async {
        await collection.put(toPoco(item));
      });
    } on IsarError catch (e, stackTrace) {
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
      final collection = await getPocoCollection();
      final isar = await db;
      await isar.writeTxn(() async {
        await collection.delete(id);
      });
    } on IsarError catch (e, stackTrace) {
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
      final collection = await getPocoCollection();
      final isar = await db;
      await isar.writeTxn(() async {
        await collection
            .where()
            .deleteAll();
      });
    } on IsarError catch (e, stackTrace) {
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

}