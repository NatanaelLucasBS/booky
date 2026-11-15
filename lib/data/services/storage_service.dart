import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Interface abstrata de persistência stateless por coleções.
/// Seção 4.3 do PLANO_DESENVOLVIMENTO.md e Slide 25 da Aula 24.
abstract interface class StorageService {
  Future<void> init();
  Future<List<Map<String, dynamic>>> getAll(String collection);
  Future<Map<String, dynamic>?> getById(String collection, String id);
  Future<void> upsert(String collection, String id, Map<String, dynamic> data);
  Future<void> delete(String collection, String id);
  Future<void> replaceCollection(String collection, List<Map<String, dynamic>> items);
  Future<void> clearCollection(String collection);
}

/// Implementação persistente local em disco (arquivos JSON na pasta de dados do app).
class LocalJsonStorageService implements StorageService {
  Directory? _dir;
  final Map<String, Map<String, Map<String, dynamic>>> _memoryCache = {};

  @override
  Future<void> init() async {
    try {
      _dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      _dir = Directory.systemTemp;
    }
  }

  File _getFile(String collection) {
    final path = _dir?.path ?? Directory.systemTemp.path;
    return File('$path/booky_$collection.json');
  }

  Future<Map<String, Map<String, dynamic>>> _loadCollection(String collection) async {
    if (_memoryCache.containsKey(collection)) {
      return _memoryCache[collection]!;
    }

    final file = _getFile(collection);
    if (!await file.exists()) {
      _memoryCache[collection] = {};
      return _memoryCache[collection]!;
    }

    try {
      final raw = await file.readAsString();
      final list = json.decode(raw) as List<dynamic>;
      final map = <String, Map<String, dynamic>>{};
      for (final item in list) {
        if (item is Map<String, dynamic> && item['id'] != null) {
          map[item['id'].toString()] = item;
        }
      }
      _memoryCache[collection] = map;
      return map;
    } catch (_) {
      _memoryCache[collection] = {};
      return _memoryCache[collection]!;
    }
  }

  Future<void> _saveCollection(String collection) async {
    final map = _memoryCache[collection] ?? {};
    final file = _getFile(collection);
    final jsonList = map.values.toList();
    await file.writeAsString(json.encode(jsonList));
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    final map = await _loadCollection(collection);
    return map.values.toList();
  }

  @override
  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    final map = await _loadCollection(collection);
    return map[id];
  }

  @override
  Future<void> upsert(String collection, String id, Map<String, dynamic> data) async {
    final map = await _loadCollection(collection);
    map[id] = Map<String, dynamic>.from(data);
    await _saveCollection(collection);
  }

  @override
  Future<void> delete(String collection, String id) async {
    final map = await _loadCollection(collection);
    if (map.containsKey(id)) {
      map.remove(id);
      await _saveCollection(collection);
    }
  }

  @override
  Future<void> replaceCollection(
    String collection,
    List<Map<String, dynamic>> items,
  ) async {
    final map = <String, Map<String, dynamic>>{};
    for (final item in items) {
      if (item['id'] != null) {
        map[item['id'].toString()] = item;
      }
    }
    _memoryCache[collection] = map;
    await _saveCollection(collection);
  }

  @override
  Future<void> clearCollection(String collection) async {
    _memoryCache[collection] = {};
    final file = _getFile(collection);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// Implementação rápida em memória (ideal para testes unitários).
class InMemoryStorageService implements StorageService {
  final Map<String, Map<String, Map<String, dynamic>>> _store = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    return _store[collection]?.values.toList() ?? [];
  }

  @override
  Future<Map<String, dynamic>?> getById(String collection, String id) async {
    return _store[collection]?[id];
  }

  @override
  Future<void> upsert(String collection, String id, Map<String, dynamic> data) async {
    _store.putIfAbsent(collection, () => {});
    _store[collection]![id] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> delete(String collection, String id) async {
    _store[collection]?.remove(id);
  }

  @override
  Future<void> replaceCollection(
    String collection,
    List<Map<String, dynamic>> items,
  ) async {
    _store[collection] = {
      for (final item in items)
        if (item['id'] != null) item['id'].toString(): item
    };
  }

  @override
  Future<void> clearCollection(String collection) async {
    _store[collection]?.clear();
  }
}
