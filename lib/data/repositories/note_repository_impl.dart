import 'dart:async';
import '../../domain/models/note_model.dart';
import '../../domain/repositories/note_repository.dart';
import '../services/storage_service.dart';

/// Implementação da Fonte Única de Verdade (SSOT) para Notas, Citações e Resenhas.
class NoteRepositoryImpl implements NoteRepository {
  static const String _collection = 'notes';
  final StorageService _storage;
  final _controller = StreamController<List<NoteModel>>.broadcast();
  List<NoteModel> _cache = [];
  bool _initialized = false;

  NoteRepositoryImpl(this._storage);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final rawList = await _storage.getAll(_collection);
    _cache = rawList.map((e) => NoteModel.fromJson(e)).toList();
    _initialized = true;
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Stream<List<NoteModel>> watchNotesByBook(String bookId) async* {
    await _ensureInitialized();
    yield _cache.where((n) => n.bookId == bookId).toList();
    yield* _controller.stream.map(
      (list) => list.where((n) => n.bookId == bookId).toList(),
    );
  }

  @override
  Future<void> saveNote(NoteModel note) async {
    await _ensureInitialized();
    await _storage.upsert(_collection, note.id, note.toJson());
    final index = _cache.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _cache[index] = note;
    } else {
      _cache.add(note);
    }
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _ensureInitialized();
    await _storage.delete(_collection, noteId);
    _cache.removeWhere((n) => n.id == noteId);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteNotesByBook(String bookId) async {
    await _ensureInitialized();
    final toRemove = _cache.where((n) => n.bookId == bookId).toList();
    for (final n in toRemove) {
      await _storage.delete(_collection, n.id);
    }
    _cache.removeWhere((n) => n.bookId == bookId);
    _controller.add(List.unmodifiable(_cache));
  }

  void dispose() {
    _controller.close();
  }
}
