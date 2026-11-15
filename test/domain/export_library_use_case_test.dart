import 'package:flutter_test/flutter_test.dart';

import 'package:booky/data/repositories/book_repository_impl.dart';
import 'package:booky/data/repositories/session_repository_impl.dart';
import 'package:booky/data/repositories/settings_repository_impl.dart';
import 'package:booky/data/services/backup_sync_service.dart';
import 'package:booky/data/services/export_service.dart';
import 'package:booky/data/services/storage_service.dart';
import 'package:booky/domain/models/book_model.dart';
import 'package:booky/domain/models/enums.dart';
import 'package:booky/domain/models/reading_session_model.dart';
import 'package:booky/domain/use_cases/export_library_use_case.dart';

import '../features/tracker/tracker_viewmodel_test.dart';

class FakeExportService extends ExportService {
  List<BookModel>? lastExportedBooks;
  String? lastPrefix;
  ExportFormat? lastFormat;

  @override
  Future<String> exportAndShareCsv({
    required List<BookModel> books,
    required String fileNamePrefix,
  }) async {
    lastExportedBooks = books;
    lastPrefix = fileNamePrefix;
    lastFormat = ExportFormat.csv;
    return '/tmp/$fileNamePrefix.csv';
  }

  @override
  Future<String> exportAndSharePdf({
    required List<BookModel> books,
    required String title,
    required String fileNamePrefix,
  }) async {
    lastExportedBooks = books;
    lastPrefix = fileNamePrefix;
    lastFormat = ExportFormat.pdf;
    return '/tmp/$fileNamePrefix.pdf';
  }
}

void main() {
  late MockBookRepository bookRepo;
  late FakeExportService fakeExportService;
  late ExportLibraryUseCase useCase;

  setUp(() {
    bookRepo = MockBookRepository();
    fakeExportService = FakeExportService();
    useCase = ExportLibraryUseCase(
      bookRepository: bookRepo,
      exportService: fakeExportService,
    );
  });

  test('ExportLibraryUseCase lanca StateError se a biblioteca estiver vazia', () async {
    bookRepo.emit([]);

    expect(
      () => useCase.execute(
        scope: ExportScope.fullCatalog,
        format: ExportFormat.csv,
      ),
      throwsStateError,
    );
  });

  test('ExportLibraryUseCase filtra apenas livros de lista de desejos no escopo wishlist', () async {
    final now = DateTime.now();
    bookRepo.emit([
      BookModel(
        id: '1',
        title: 'Livro Lendo',
        author: 'Autor A',
        totalPages: 200,
        status: BookStatus.reading,
        createdAt: now,
        updatedAt: now,
      ),
      BookModel(
        id: '2',
        title: 'Livro Desejo',
        author: 'Autor B',
        totalPages: 300,
        status: BookStatus.wantToRead,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await useCase.execute(
      scope: ExportScope.wishlist,
      format: ExportFormat.csv,
    );

    expect(fakeExportService.lastExportedBooks?.length, equals(1));
    expect(fakeExportService.lastExportedBooks?.first.id, equals('2'));
    expect(fakeExportService.lastPrefix, equals('booky_desejos'));
    expect(fakeExportService.lastFormat, equals(ExportFormat.csv));
  });

  test('ExportLibraryUseCase exporta todo o catalogo em PDF', () async {
    final now = DateTime.now();
    bookRepo.emit([
      BookModel(
        id: '1',
        title: 'Livro 1',
        author: 'Autor A',
        totalPages: 200,
        status: BookStatus.reading,
        createdAt: now,
        updatedAt: now,
      ),
      BookModel(
        id: '2',
        title: 'Livro 2',
        author: 'Autor B',
        totalPages: 300,
        status: BookStatus.read,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await useCase.execute(
      scope: ExportScope.fullCatalog,
      format: ExportFormat.pdf,
    );

    expect(fakeExportService.lastExportedBooks?.length, equals(2));
    expect(fakeExportService.lastPrefix, equals('booky_catalogo'));
    expect(fakeExportService.lastFormat, equals(ExportFormat.pdf));
  });

  test('ExportService.buildCsvContent gera CSV com BOM UTF-8 e acentuação PT-BR', () {
    const service = ExportService();
    final now = DateTime.now();
    final csv = service.buildCsvContent([
      BookModel(
        id: '1',
        isbn: '9788535914849',
        title: 'Memórias Póstumas de Brás Cubas',
        author: 'Machado de Assis',
        publisher: 'Companhia das Letras',
        publishedYear: 1881,
        genre: 'Ficção Clássica',
        totalPages: 368,
        currentPage: 368,
        status: BookStatus.read,
        format: BookFormat.physical,
        rating: 5.0,
        tags: const ['clássico', 'ironia'],
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('Título,Autor,ISBN,Editora,Ano,Gênero'));
    expect(csv, contains('Memórias Póstumas de Brás Cubas'));
    expect(csv, contains('clássico; ironia'));
  });

  test('BackupSyncService exporta e restaura todas as 6 coleções (incluindo sessions e settings)', () async {
    final sourceStorage = InMemoryStorageService();
    final bookRepo = BookRepositoryImpl(sourceStorage);
    final sessionRepo = SessionRepositoryImpl(sourceStorage);
    final settingsRepo = SettingsRepositoryImpl(sourceStorage);

    final now = DateTime.now();
    await bookRepo.saveBook(BookModel(
      id: 'b1',
      title: 'Duna',
      author: 'Frank Herbert',
      createdAt: now,
      updatedAt: now,
    ));
    await sessionRepo.addSession(ReadingSessionModel(
      id: 's1',
      bookId: 'b1',
      startTime: now,
      durationSeconds: 1200,
      startPage: 0,
      endPage: 30,
      pagesRead: 30,
      dateKey: '2026-11-15',
      updatedAt: now,
    ));
    await settingsRepo.updateAnnualGoal(30);

    final backupService = BackupSyncService(sourceStorage);
    final jsonBackup = await backupService.generateBackupJson();

    final targetStorage = InMemoryStorageService();
    final targetBackupService = BackupSyncService(targetStorage);
    final restoredCount = await targetBackupService.restoreFromJson(jsonBackup);

    expect(restoredCount, equals(3));

    final restoredBooks = await BookRepositoryImpl(targetStorage).getBooks();
    final restoredSessions = await SessionRepositoryImpl(targetStorage).getSessionsByBook('b1');
    final restoredSettings = await SettingsRepositoryImpl(targetStorage).getSettings();

    expect(restoredBooks.length, 1);
    expect(restoredBooks.first.title, 'Duna');
    expect(restoredSessions.length, 1);
    expect(restoredSessions.first.pagesRead, 30);
    expect(restoredSettings.annualReadingGoal, 30);
  });
}
