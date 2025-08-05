abstract class IBaseRepository<T> {

  Future<List<T>> getAll();
  Future<T?> getById(int id);
  Future<T?> add(T item);
  Future<void> edit(T item);
  Future<void> delete(int id);
  Future<void> deleteAll();

}
