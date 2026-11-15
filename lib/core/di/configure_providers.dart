import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/repositories/book_repository_impl.dart';
import '../../data/repositories/loan_repository_impl.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/shelf_repository_impl.dart';
import '../../data/services/book_api_service.dart';
import '../../data/services/ocr_service.dart';
import '../../data/services/storage_service.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/loan_repository.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/shelf_repository.dart';

/// Árvore de Injeção de Dependências no padrão do Prof. Taniro (`todo_app_arch`).
class ConfigureProviders {
  final List<SingleChildWidget> providers;

  ConfigureProviders({required this.providers});

  static Future<ConfigureProviders> createDependencyTree() async {
    // 1. Serviços Stateless
    final storageService = LocalJsonStorageService();
    await storageService.init();

    final bookApiService = BookApiService();
    final ocrService = OcrService();

    // 2. Repositórios SSOT
    final bookRepository = BookRepositoryImpl(storageService);
    final shelfRepository = ShelfRepositoryImpl(storageService);
    final sessionRepository = SessionRepositoryImpl(storageService);
    final noteRepository = NoteRepositoryImpl(storageService);
    final loanRepository = LoanRepositoryImpl(storageService);
    final settingsRepository = SettingsRepositoryImpl(storageService);

    return ConfigureProviders(
      providers: [
        // Services
        Provider<StorageService>.value(value: storageService),
        Provider<BookApiService>.value(value: bookApiService),
        Provider<OcrService>.value(value: ocrService),

        // Repositories (SSOT)
        Provider<BookRepository>.value(value: bookRepository),
        Provider<ShelfRepository>.value(value: shelfRepository),
        Provider<SessionRepository>.value(value: sessionRepository),
        Provider<NoteRepository>.value(value: noteRepository),
        Provider<LoanRepository>.value(value: loanRepository),
        Provider<SettingsRepository>.value(value: settingsRepository),
      ],
    );
  }
}
