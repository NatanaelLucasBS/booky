import 'dart:convert';
import 'dart:io';
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
    'reading_sessions',
    'notes',
    'loans',
    'app_settings',
  ];

  /// Gera um snapshot completo em formato JSON e abre o compartilhamento.
  Future<String> exportBackupAndShare() async {
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

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/booky_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: 'Backup da Biblioteca Booky',
    );

    return file.path;
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

    for (final col in _collections) {
      if (collections.containsKey(col)) {
        final list = collections[col];
        if (list is List) {
          for (final item in list) {
            if (item is Map<String, dynamic> && item.containsKey('id')) {
              await _storageService.upsert(col, item['id'] as String, item);
              restoredCount++;
            }
          }
        }
      }
    }

    return restoredCount;
  }
}
