import 'package:flutter_test/flutter_test.dart';

import 'package:booky/data/services/export_service.dart';
import 'package:booky/domain/models/book_model.dart';
import 'package:booky/domain/models/enums.dart';
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
}
