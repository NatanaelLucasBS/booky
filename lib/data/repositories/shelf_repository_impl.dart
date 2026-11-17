import 'dart:async';
import '../../domain/models/shelf_model.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../services/storage_service.dart';

/// Implementação da Fonte Única de Verdade (SSOT) para Estantes Temáticas.
class ShelfRepositoryImpl implements ShelfRepository {
  static const String _collection = 'shelves';
  final StorageService _storage;
  final _controller = StreamController<List<ShelfModel>>.broadcast();
  List<ShelfModel> _cache = [];
  bool _initialized = false;

  ShelfRepositoryImpl(this._storage);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final rawList = await _storage.getAll(_collection);
    _cache = rawList.map((e) => ShelfModel.fromJson(e)).toList();
    _initialized = true;
    _controller.add(List.unmodifiable(_cache));
  }

  /// Recarrega o cache a partir do StorageService e notifica os streams SSOT.
  Future<void> reload() async {
    _initialized = false;
    await _ensureInitialized();
  }

  @override
  Stream<List<ShelfModel>> watchShelves() async* {
    await _ensureInitialized();
    yield List.unmodifiable(_cache);
    yield* _controller.stream;
  }

  @override
  Future<List<ShelfModel>> getShelves() async {
    await _ensureInitialized();
    return List.unmodifiable(_cache);
  }

  @override
  Future<void> saveShelf(ShelfModel shelf) async {
    await _ensureInitialized();
    await _storage.upsert(_collection, shelf.id, shelf.toJson());
    final index = _cache.indexWhere((s) => s.id == shelf.id);
    if (index >= 0) {
      _cache[index] = shelf;
    } else {
      _cache.add(shelf);
    }
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteShelf(String shelfId) async {
    await _ensureInitialized();
    await _storage.delete(_collection, shelfId);
    _cache.removeWhere((s) => s.id == shelfId);
    _controller.add(List.unmodifiable(_cache));
  }

  void dispose() {
    _controller.close();
  }
}
