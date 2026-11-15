import 'dart:async';
import '../../domain/models/book_model.dart';
import '../../domain/repositories/book_repository.dart';
import '../services/storage_service.dart';

/// Implementação da Fonte Única de Verdade (SSOT) para Livros.
/// Consome StorageService e não depende de nenhum outro Repositório (Slide 23 da Aula 24).
class BookRepositoryImpl implements BookRepository {
  static const String _collection = 'books';
  final StorageService _storage;
  final _controller = StreamController<List<BookModel>>.broadcast();
  List<BookModel> _cache = [];
  bool _initialized = false;

  BookRepositoryImpl(this._storage);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final rawList = await _storage.getAll(_collection);
    _cache = rawList.map((e) => BookModel.fromJson(e)).toList();
    _initialized = true;
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Stream<List<BookModel>> watchBooks() async* {
    await _ensureInitialized();
    yield List.unmodifiable(_cache);
    yield* _controller.stream;
  }

  @override
  Stream<BookModel?> watchBookById(String bookId) async* {
    await _ensureInitialized();
    yield _cache.where((b) => b.id == bookId).firstOrNull;
    yield* _controller.stream.map(
      (list) => list.where((b) => b.id == bookId).firstOrNull,
    );
  }

  @override
  Future<List<BookModel>> getBooks() async {
    await _ensureInitialized();
    return List.unmodifiable(_cache);
  }

  @override
  Future<BookModel?> getBookById(String bookId) async {
    await _ensureInitialized();
    return _cache.where((b) => b.id == bookId).firstOrNull;
  }

  @override
  Future<void> saveBook(BookModel book) async {
    await _ensureInitialized();
    await _storage.upsert(_collection, book.id, book.toJson());
    final index = _cache.indexWhere((b) => b.id == book.id);
    if (index >= 0) {
      _cache[index] = book;
    } else {
      _cache.add(book);
    }
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteBook(String bookId) async {
    await _ensureInitialized();
    await _storage.delete(_collection, bookId);
    _cache.removeWhere((b) => b.id == bookId);
    _controller.add(List.unmodifiable(_cache));
  }

  void dispose() {
    _controller.close();
  }
}
