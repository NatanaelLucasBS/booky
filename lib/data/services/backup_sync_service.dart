import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'storage_service.dart';

/// Serviço stateless para geração de Backup e Restauração/Sincronização dos dados locais.
/// Slide 25 da Aula 24 (Arquitetura Recomendada).
class BackupSyncService {
  final StorageService _storageService;

  const BackupSyncService(this._storageService);

  static const List<String> _collections = [
    'books',
    'shelves',
    'sessions',
    'notes',
    'loans',
    'settings',
  ];

  static const Map<String, String> _legacyCollectionAliases = {
    'reading_sessions': 'sessions',
    'app_settings': 'settings',
  };

  /// Gera um snapshot completo em formato JSON e abre o compartilhamento.
  Future<String> exportBackupAndShare() async {
    final jsonString = await generateBackupJson();
    final fileName =
        'booky_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    if (kIsWeb) {
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: 'application/json')],
        text: 'Backup da Biblioteca Booky',
      );
      return fileName;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonString, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: 'Backup da Biblioteca Booky',
    );

    return file.path;
  }

  /// Gera a String JSON do snapshot completo sem disparar o share_plus (útil para testes).
  Future<String> generateBackupJson() async {
    final payload = <String, dynamic>{
      'version': '1.0.0',
      'appName': 'Booky',
      'exportedAt': DateTime.now().toIso8601String(),
      'collections': <String, dynamic>{},
    };

    final collectionsMap = payload['collections'] as Map<String, dynamic>;

    for (final col in _collections) {
      final records = await _storageService.getAll(col);
      collectionsMap[col] = records;
    }

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Restaura dados a partir de uma String JSON de backup.
  Future<int> restoreFromJson(String rawJson) async {
    final dynamic decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Arquivo de backup inválido.');
    }

    final collections = decoded['collections'];
    if (collections is! Map<String, dynamic>) {
      throw const FormatException('Estrutura de coleções ausente no backup.');
    }

    int restoredCount = 0;

    for (final entry in collections.entries) {
      final targetCol = _legacyCollectionAliases[entry.key] ?? entry.key;
      if (!_collections.contains(targetCol)) continue;

      final list = entry.value;
      if (list is List) {
        await _storageService.clearCollection(targetCol);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final id = (item['id'] as String?) ??
                (targetCol == 'settings' ? 'app_settings' : null);
            if (id != null && id.isNotEmpty) {
              final data = Map<String, dynamic>.from(item);
              data['id'] = id;
              await _storageService.upsert(targetCol, id, data);
              restoredCount++;
            }
          }
        }
      }
    }

    return restoredCount;
  }
}
