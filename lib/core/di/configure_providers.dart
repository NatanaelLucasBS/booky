import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/repositories/book_repository_impl.dart';
import '../../data/repositories/loan_repository_impl.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/shelf_repository_impl.dart';
import '../../data/services/backup_sync_service.dart';
import '../../data/services/book_api_service.dart';
import '../../data/services/export_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/ocr_service.dart';
import '../../data/services/storage_service.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/loan_repository.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../../domain/use_cases/delete_book_use_case.dart';
import '../../domain/use_cases/export_library_use_case.dart';
import '../../domain/use_cases/get_dashboard_stats_use_case.dart';
import '../../domain/use_cases/register_loan_use_case.dart';
import '../../domain/use_cases/restore_backup_use_case.dart';
import '../../domain/use_cases/return_loan_use_case.dart';
import '../../domain/use_cases/save_reading_session_use_case.dart';
import '../theme/theme_controller.dart';

/// Árvore de Injeção de Dependências no padrão do Prof. Taniro (`todo_app_arch`).
class ConfigureProviders {
  final List<SingleChildWidget> providers;

  ConfigureProviders({required this.providers});

  static Future<ConfigureProviders> createDependencyTree() async {
    // 1. Serviços Stateless (com fallback seguro em memória quando executado no Chrome/Web)
    final StorageService storageService =
        kIsWeb ? InMemoryStorageService() : LocalJsonStorageService();
    await storageService.init();

    final bookApiService = BookApiService();
    final ocrService = OcrService();
    final notificationService = NotificationService();
    await notificationService.init();
    const exportService = ExportService();
    final backupSyncService = BackupSyncService(storageService);

    // 2. Repositórios Reativos SSOT (Single Source of Truth)
    final bookRepository = BookRepositoryImpl(storageService);
    final shelfRepository = ShelfRepositoryImpl(storageService);
    final sessionRepository = SessionRepositoryImpl(storageService);
    final noteRepository = NoteRepositoryImpl(storageService);
    final loanRepository = LoanRepositoryImpl(storageService);
    final settingsRepository = SettingsRepositoryImpl(storageService);

    // 3. Casos de Uso (Orquestradores de regras de negócio entre repositórios)
    final saveReadingSessionUseCase = SaveReadingSessionUseCase(
      bookRepository: bookRepository,
      sessionRepository: sessionRepository,
    );

    final registerLoanUseCase = RegisterLoanUseCase(
      loanRepository: loanRepository,
      notificationService: notificationService,
    );

    final returnLoanUseCase = ReturnLoanUseCase(
      loanRepository: loanRepository,
      notificationService: notificationService,
    );

    final deleteBookUseCase = DeleteBookUseCase(
      bookRepository: bookRepository,
      noteRepository: noteRepository,
      loanRepository: loanRepository,
      sessionRepository: sessionRepository,
      notificationService: notificationService,
    );

    final getDashboardStatsUseCase = GetDashboardStatsUseCase(
      bookRepository: bookRepository,
      sessionRepository: sessionRepository,
      loanRepository: loanRepository,
      settingsRepository: settingsRepository,
    );

    final exportLibraryUseCase = ExportLibraryUseCase(
      bookRepository: bookRepository,
      exportService: exportService,
    );

    final restoreBackupUseCase = RestoreBackupUseCase(
      backupSyncService: backupSyncService,
      onReloadRepositories: [
        bookRepository.reload,
        shelfRepository.reload,
        sessionRepository.reload,
        noteRepository.reload,
        loanRepository.reload,
        settingsRepository.reload,
      ],
    );

    return ConfigureProviders(
      providers: [
        // Theme
        ChangeNotifierProvider<ThemeController>.value(value: themeController),

        // Services
        Provider<StorageService>.value(value: storageService),
        Provider<BookApiService>.value(value: bookApiService),
        Provider<OcrService>.value(value: ocrService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<ExportService>.value(value: exportService),
        Provider<BackupSyncService>.value(value: backupSyncService),

        // Repositories (SSOT)
        Provider<BookRepository>.value(value: bookRepository),
        Provider<ShelfRepository>.value(value: shelfRepository),
        Provider<SessionRepository>.value(value: sessionRepository),
        Provider<NoteRepository>.value(value: noteRepository),
        Provider<LoanRepository>.value(value: loanRepository),
        Provider<SettingsRepository>.value(value: settingsRepository),

        // UseCases
        Provider<SaveReadingSessionUseCase>.value(value: saveReadingSessionUseCase),
        Provider<RegisterLoanUseCase>.value(value: registerLoanUseCase),
        Provider<ReturnLoanUseCase>.value(value: returnLoanUseCase),
        Provider<DeleteBookUseCase>.value(value: deleteBookUseCase),
        Provider<GetDashboardStatsUseCase>.value(value: getDashboardStatsUseCase),
        Provider<ExportLibraryUseCase>.value(value: exportLibraryUseCase),
        Provider<RestoreBackupUseCase>.value(value: restoreBackupUseCase),
      ],
    );
  }
}
