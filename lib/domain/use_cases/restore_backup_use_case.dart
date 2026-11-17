import '../../data/services/backup_sync_service.dart';

/// Orquestra a restauração de backup JSON via [BackupSyncService] e recarrega
/// os repositórios SSOT para que todas as telas atualizem imediatamente via Stream.
class RestoreBackupUseCase {
  final BackupSyncService _backupSyncService;
  final List<Future<void> Function()> _onReloadRepositories;

  const RestoreBackupUseCase({
    required BackupSyncService backupSyncService,
    required List<Future<void> Function()> onReloadRepositories,
  })  : _backupSyncService = backupSyncService,
        _onReloadRepositories = onReloadRepositories;

  Future<int> execute(String rawJson) async {
    final restoredCount = await _backupSyncService.restoreFromJson(rawJson);
    await Future.wait(_onReloadRepositories.map((reload) => reload()));
    return restoredCount;
  }
}
