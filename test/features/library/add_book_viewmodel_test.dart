import 'package:flutter_test/flutter_test.dart';
import 'package:booky/data/services/book_api_service.dart';
import 'package:booky/data/services/storage_service.dart';
import 'package:booky/data/repositories/book_repository_impl.dart';
import 'package:booky/data/repositories/shelf_repository_impl.dart';
import 'package:booky/domain/models/enums.dart';
import 'package:booky/domain/models/book_model.dart';
import 'package:booky/features/library/presentation/viewmodels/add_book_viewmodel.dart';

class FakeBookApiService extends BookApiService {
  final BookLookupResult? mockResult;

  FakeBookApiService({this.mockResult});

  @override
  Future<BookLookupResult?> lookupBookByIsbn(String rawIsbn) async {
    return mockResult;
  }
}

void main() {
  late InMemoryStorageService storage;
  late BookRepositoryImpl bookRepo;
  late ShelfRepositoryImpl shelfRepo;

  setUp(() {
    storage = InMemoryStorageService();
    bookRepo = BookRepositoryImpl(storage);
    shelfRepo = ShelfRepositoryImpl(storage);
  });

  group('AddBookViewModel - Cadastro e Validação', () {
    test('falha ao salvar se o título estiver vazio', () async {
      final vm = AddBookViewModel(
        bookRepository: bookRepo,
        shelfRepository: shelfRepo,
        bookApiService: FakeBookApiService(),
      );

      final success = await vm.saveBook();
      expect(success, isFalse);
      expect(vm.errorMessage, isNotNull);
    });

    test('salva livro com sucesso no BookRepository', () async {
      final vm = AddBookViewModel(
        bookRepository: bookRepo,
        shelfRepository: shelfRepo,
        bookApiService: FakeBookApiService(),
      );

      vm.setTitle('O Alienista');
      vm.setAuthor('Machado de Assis');
      vm.setTotalPages(120);
      vm.setStatus(BookStatus.reading);

      final success = await vm.saveBook();
      expect(success, isTrue);

      final books = await bookRepo.getBooks();
      expect(books.length, 1);
      expect(books.first.title, 'O Alienista');
      expect(books.first.author, 'Machado de Assis');
      expect(books.first.totalPages, 120);
      expect(books.first.status, BookStatus.reading);
      expect(books.first.startedAt, isNotNull);
    });

    test('preenche campos e muda para modo manual ao consultar ISBN com sucesso', () async {
      final fakeApi = FakeBookApiService(
        mockResult: const BookLookupResult(
          isbn: '9788532511010',
          title: 'Dom Casmurro',
          author: 'Machado de Assis',
          totalPages: 256,
          genre: 'Romance',
          publishedYear: 1899,
          publisher: 'Garnier',
        ),
      );

      final vm = AddBookViewModel(
        bookRepository: bookRepo,
        shelfRepository: shelfRepo,
        bookApiService: fakeApi,
      );

      expect(vm.activeMode, 0); // Scanner
      final success = await vm.lookupByIsbn('9788532511010');

      expect(success, isTrue);
      expect(vm.activeMode, 1); // Manual preenchido
      expect(vm.title, 'Dom Casmurro');
      expect(vm.author, 'Machado de Assis');
      expect(vm.totalPages, 256);
      expect(vm.genre, 'Romance');
    });

    test('gerencia tags e estantes temáticas corretamente', () async {
      final vm = AddBookViewModel(
        bookRepository: bookRepo,
        shelfRepository: shelfRepo,
        bookApiService: FakeBookApiService(),
      );

      vm.addTag('clássico');
      vm.addTag('nacional');
      expect(vm.tags, ['clássico', 'nacional']);

      vm.removeTag('clássico');
      expect(vm.tags, ['nacional']);

      await vm.createShelf('Favoritos', 'Livros do coração');
      expect(vm.availableShelves.length, 1);
      expect(vm.selectedShelfIds.length, 1);
      expect(vm.selectedShelfIds.first, vm.availableShelves.first.id);
    });

    test('carrega dados existentes em modo edição', () {
      final existing = BookModel(
        id: '123',
        title: 'Grande Sertão: Veredas',
        author: 'Guimarães Rosa',
        totalPages: 600,
        status: BookStatus.read,
        format: BookFormat.physical,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final vm = AddBookViewModel(
        bookRepository: bookRepo,
        shelfRepository: shelfRepo,
        bookApiService: FakeBookApiService(),
        initialBook: existing,
      );

      expect(vm.activeMode, 1);
      expect(vm.title, 'Grande Sertão: Veredas');
      expect(vm.author, 'Guimarães Rosa');
      expect(vm.totalPages, 600);
      expect(vm.status, BookStatus.read);
    });

    test('ao editar livro Lido para Lendo ou Quero Ler, limpa finishedAt e ajusta currentPage', () async {
      final now = DateTime.now();
      final existing = BookModel(
        id: 'edit-1',
        title: 'Memórias Póstumas',
        author: 'Machado de Assis',
        totalPages: 300,
        currentPage: 300,
        status: BookStatus.read,
        format: BookFormat.physical,
        startedAt: now,
        finishedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final vm = AddBookViewModel(
        bookRepository: bookRepo,
        shelfRepository: shelfRepo,
        bookApiService: FakeBookApiService(),
        initialBook: existing,
      );

      vm.setStatus(BookStatus.reading);
      vm.setTotalPages(200);
      await vm.saveBook();

      var saved = await bookRepo.getBookById('edit-1');
      expect(saved!.status, BookStatus.reading);
      expect(saved.finishedAt, isNull);
      expect(saved.currentPage, 200);

      final vmReset = AddBookViewModel(
        bookRepository: bookRepo,
        shelfRepository: shelfRepo,
        bookApiService: FakeBookApiService(),
        initialBook: saved,
      );
      vmReset.setStatus(BookStatus.wantToRead);
      await vmReset.saveBook();

      saved = await bookRepo.getBookById('edit-1');
      expect(saved!.status, BookStatus.wantToRead);
      expect(saved.startedAt, isNull);
      expect(saved.finishedAt, isNull);
      expect(saved.currentPage, 0);
    });
  });
}
