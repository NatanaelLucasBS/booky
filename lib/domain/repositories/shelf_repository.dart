import '../models/shelf_model.dart';

/// Contrato canônico do Repositório de Estantes Temáticas (SSOT).
abstract interface class ShelfRepository {
  Stream<List<ShelfModel>> watchShelves();
  Future<List<ShelfModel>> getShelves();
  Future<void> saveShelf(ShelfModel shelf);
  Future<void> deleteShelf(String shelfId);
}
