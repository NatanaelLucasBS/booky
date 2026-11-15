import '../../data/services/export_service.dart';
import '../models/enums.dart';
import '../repositories/book_repository.dart';

/// Caso de Uso para exportação da biblioteca (PDF ou CSV).
/// Orquestra a filtragem pelo escopo e aciona o ExportService stateless.
class ExportLibraryUseCase {
  final BookRepository _bookRepository;
  final ExportService _exportService;

  const ExportLibraryUseCase({
    required BookRepository bookRepository,
    required ExportService exportService,
  })  : _bookRepository = bookRepository,
        _exportService = exportService;

  Future<String> execute({
    required ExportScope scope,
    required ExportFormat format,
  }) async {
    final allBooks = await _bookRepository.getBooks();

    final booksToExport = scope == ExportScope.wishlist
        ? allBooks.where((b) => b.status == BookStatus.wantToRead).toList()
        : allBooks;

    if (booksToExport.isEmpty) {
      throw StateError(
        scope == ExportScope.wishlist
            ? 'Nenhum livro encontrado na lista de desejos.'
            : 'A biblioteca está vazia. Adicione livros antes de exportar.',
      );
    }

    final prefix = scope == ExportScope.wishlist ? 'booky_desejos' : 'booky_catalogo';

    if (format == ExportFormat.csv) {
      return _exportService.exportAndShareCsv(
        books: booksToExport,
        fileNamePrefix: prefix,
      );
    } else {
      return _exportService.exportAndSharePdf(
        books: booksToExport,
        title: scope.label,
        fileNamePrefix: prefix,
      );
    }
  }
}
