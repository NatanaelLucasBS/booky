import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:booky/main.dart';
import 'package:booky/core/di/configure_providers.dart';
import 'package:booky/data/services/storage_service.dart';
import 'package:booky/data/services/book_api_service.dart';
import 'package:booky/data/services/ocr_service.dart';
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

void main() {
  testWidgets('BookyApp smoke test inicializa com sucesso', (WidgetTester tester) async {
    final storage = InMemoryStorageService();
    final di = ConfigureProviders(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<BookApiService>.value(value: BookApiService()),
        Provider<OcrService>.value(value: OcrService()),
        Provider<BookRepository>.value(value: BookRepositoryImpl(storage)),
        Provider<ShelfRepository>.value(value: ShelfRepositoryImpl(storage)),
        Provider<SessionRepository>.value(value: SessionRepositoryImpl(storage)),
        Provider<NoteRepository>.value(value: NoteRepositoryImpl(storage)),
        Provider<LoanRepository>.value(value: LoanRepositoryImpl(storage)),
        Provider<SettingsRepository>.value(value: SettingsRepositoryImpl(storage)),
      ],
    );

    await tester.pumpWidget(BookyApp(di: di));
    expect(find.text('Início'), findsWidgets);
  });
}
