import '../models/shelf_model.dart';

// Repositório de estantes temáticas
abstract interface class ShelfRepository {
  Stream<List<ShelfModel>> watchShelves();
  Future<List<ShelfModel>> getShelves();
  Future<void> saveShelf(ShelfModel shelf);
  Future<void> deleteShelf(String shelfId);
}
