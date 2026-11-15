import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:booky/main.dart';
import 'package:booky/core/di/configure_providers.dart';
import 'package:booky/data/services/storage_service.dart';
import 'package:booky/data/services/book_api_service.dart';
import 'package:booky/data/services/ocr_service.dart';
import 'package:booky/data/services/notification_service.dart';
import 'package:booky/domain/repositories/book_repository.dart';
import 'package:booky/domain/repositories/shelf_repository.dart';
import 'package:booky/domain/repositories/session_repository.dart';
import 'package:booky/domain/repositories/note_repository.dart';
import 'package:booky/domain/repositories/loan_repository.dart';
import 'package:booky/domain/repositories/settings_repository.dart';
import 'package:booky/data/repositories/book_repository_impl.dart';
import 'package:booky/data/repositories/shelf_repository_impl.dart';
import 'package:booky/data/repositories/session_repository_impl.dart';
import 'package:booky/data/repositories/note_repository_impl.dart';
import 'package:booky/data/repositories/loan_repository_impl.dart';
import 'package:booky/data/repositories/settings_repository_impl.dart';
import 'package:booky/domain/use_cases/save_reading_session_use_case.dart';
import 'package:booky/domain/use_cases/register_loan_use_case.dart';
import 'package:booky/domain/use_cases/return_loan_use_case.dart';
import 'package:booky/domain/use_cases/delete_book_use_case.dart';
import 'package:booky/domain/use_cases/get_dashboard_stats_use_case.dart';

void main() {
  testWidgets('BookyApp smoke test inicializa com sucesso', (WidgetTester tester) async {
    final storage = InMemoryStorageService();
    final bookRepo = BookRepositoryImpl(storage);
    final shelfRepo = ShelfRepositoryImpl(storage);
    final sessionRepo = SessionRepositoryImpl(storage);
    final noteRepo = NoteRepositoryImpl(storage);
    final loanRepo = LoanRepositoryImpl(storage);
    final settingsRepo = SettingsRepositoryImpl(storage);

    final di = ConfigureProviders(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<BookApiService>.value(value: BookApiService()),
        Provider<OcrService>.value(value: OcrService()),
        Provider<NotificationService>.value(value: NotificationService()),
        Provider<BookRepository>.value(value: bookRepo),
        Provider<ShelfRepository>.value(value: shelfRepo),
        Provider<SessionRepository>.value(value: sessionRepo),
        Provider<NoteRepository>.value(value: noteRepo),
        Provider<LoanRepository>.value(value: loanRepo),
        Provider<SettingsRepository>.value(value: settingsRepo),
        Provider<SaveReadingSessionUseCase>.value(
          value: SaveReadingSessionUseCase(
            bookRepository: bookRepo,
            sessionRepository: sessionRepo,
          ),
        ),
        Provider<DeleteBookUseCase>.value(
          value: DeleteBookUseCase(
            bookRepository: bookRepo,
            noteRepository: noteRepo,
            loanRepository: loanRepo,
            sessionRepository: sessionRepo,
          ),
        ),
        Provider<GetDashboardStatsUseCase>.value(
          value: GetDashboardStatsUseCase(
            bookRepository: bookRepo,
            sessionRepository: sessionRepo,
            loanRepository: loanRepo,
            settingsRepository: settingsRepo,
          ),
        ),
      ],
    );

    await tester.pumpWidget(BookyApp(di: di));
    await tester.pumpAndSettle();
    expect(find.text('Início'), findsWidgets);
  });
}
