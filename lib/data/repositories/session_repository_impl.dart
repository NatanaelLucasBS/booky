import 'dart:async';
import '../../domain/models/reading_session_model.dart';
import '../../domain/repositories/session_repository.dart';
import '../services/storage_service.dart';

/// Implementação da Fonte Única de Verdade (SSOT) para Sessões de Leitura.
class SessionRepositoryImpl implements SessionRepository {
  static const String _collection = 'sessions';
  final StorageService _storage;
  final _controller = StreamController<List<ReadingSessionModel>>.broadcast();
  List<ReadingSessionModel> _cache = [];
  bool _initialized = false;

  SessionRepositoryImpl(this._storage);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final rawList = await _storage.getAll(_collection);
    _cache = rawList.map((e) => ReadingSessionModel.fromJson(e)).toList();
    _initialized = true;
    _controller.add(List.unmodifiable(_cache));
  }

  /// Recarrega o cache a partir do StorageService e notifica os streams SSOT.
  Future<void> reload() async {
    _initialized = false;
    await _ensureInitialized();
  }

  @override
  Stream<List<ReadingSessionModel>> watchSessions() async* {
    await _ensureInitialized();
    yield List.unmodifiable(_cache);
    yield* _controller.stream;
  }

  @override
  Stream<List<ReadingSessionModel>> watchSessionsByBook(String bookId) async* {
    await _ensureInitialized();
    yield _cache.where((s) => s.bookId == bookId).toList();
    yield* _controller.stream.map(
      (list) => list.where((s) => s.bookId == bookId).toList(),
    );
  }

  @override
  Future<List<ReadingSessionModel>> getSessionsByBook(String bookId) async {
    await _ensureInitialized();
    return _cache.where((s) => s.bookId == bookId).toList();
  }

  @override
  Future<void> addSession(ReadingSessionModel session) async {
    await _ensureInitialized();
    await _storage.upsert(_collection, session.id, session.toJson());
    _cache.add(session);
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteSessionsByBook(String bookId) async {
    await _ensureInitialized();
    final toRemove = _cache.where((s) => s.bookId == bookId).toList();
    for (final s in toRemove) {
      await _storage.delete(_collection, s.id);
    }
    _cache.removeWhere((s) => s.bookId == bookId);
    _controller.add(List.unmodifiable(_cache));
  }

  void dispose() {
    _controller.close();
  }
}
