import 'package:flutter_test/flutter_test.dart';
import 'package:booky/data/repositories/book_repository_impl.dart';
import 'package:booky/data/repositories/shelf_repository_impl.dart';
import 'package:booky/data/services/backup_sync_service.dart';
import 'package:booky/data/services/storage_service.dart';
import 'package:booky/domain/models/book_model.dart';
import 'package:booky/domain/use_cases/restore_backup_use_case.dart';

void main() {
  test('RestoreBackupUseCase restaura dados e atualiza streams dos repositorios', () async {
    final sourceStorage = InMemoryStorageService();
    final sourceBookRepo = BookRepositoryImpl(sourceStorage);
    final now = DateTime.now();
    await sourceBookRepo.saveBook(BookModel(
      id: 'b-restored',
      title: '1984',
      author: 'George Orwell',
      createdAt: now,
      updatedAt: now,
    ));

    final backupJson = await BackupSyncService(sourceStorage).generateBackupJson();

    final targetStorage = InMemoryStorageService();
    final targetBookRepo = BookRepositoryImpl(targetStorage);
    final targetShelfRepo = ShelfRepositoryImpl(targetStorage);
    final restoreUseCase = RestoreBackupUseCase(
      backupSyncService: BackupSyncService(targetStorage),
      onReloadRepositories: [
        targetBookRepo.reload,
        targetShelfRepo.reload,
      ],
    );

    final emittedSnapshots = <List<BookModel>>[];
    final sub = targetBookRepo.watchBooks().listen(emittedSnapshots.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final restoredCount = await restoreUseCase.execute(backupJson);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(restoredCount, 1);
    expect(emittedSnapshots.last.length, 1);
    expect(emittedSnapshots.last.first.title, '1984');

    await sub.cancel();
  });
}
