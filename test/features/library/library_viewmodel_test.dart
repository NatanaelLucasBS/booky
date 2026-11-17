import 'package:flutter_test/flutter_test.dart';
import 'package:booky/data/services/storage_service.dart';
import 'package:booky/data/repositories/book_repository_impl.dart';
import 'package:booky/data/repositories/loan_repository_impl.dart';
import 'package:booky/data/repositories/shelf_repository_impl.dart';
import 'package:booky/domain/models/book_model.dart';
import 'package:booky/domain/models/enums.dart';
import 'package:booky/domain/models/loan_model.dart';
import 'package:booky/domain/models/shelf_model.dart';
import 'package:booky/features/library/presentation/viewmodels/library_viewmodel.dart';

void main() {
  late InMemoryStorageService storage;
  late BookRepositoryImpl bookRepo;
  late LoanRepositoryImpl loanRepo;
  late ShelfRepositoryImpl shelfRepo;

  setUp(() {
    storage = InMemoryStorageService();
    bookRepo = BookRepositoryImpl(storage);
    loanRepo = LoanRepositoryImpl(storage);
    shelfRepo = ShelfRepositoryImpl(storage);
  });

  group('LibraryViewModel - Filtros e Estatísticas', () {
    test('calcula contadores dinâmicos e aplica filtros rápidos', () async {
      final now = DateTime.now();

      await bookRepo.saveBook(BookModel(
        id: '1',
        title: 'O Hobbit',
        author: 'J.R.R. Tolkien',
        status: BookStatus.reading,
        createdAt: now,
        updatedAt: now,
      ));

      await bookRepo.saveBook(BookModel(
        id: '2',
        title: 'Duna',
        author: 'Frank Herbert',
        status: BookStatus.read,
        createdAt: now,
        updatedAt: now,
      ));

      await bookRepo.saveBook(BookModel(
        id: '3',
        title: 'Fundação',
        author: 'Isaac Asimov',
        status: BookStatus.wantToRead,
        createdAt: now,
        updatedAt: now,
      ));

      // Empréstimo ativo para o livro 2
      await loanRepo.saveLoan(LoanModel(
        id: 'l1',
        bookId: '2',
        borrowerName: 'Carlos',
        borrowerContact: '9999-9999',
        loanDate: now.subtract(const Duration(days: 2)),
        expectedReturnDate: now.add(const Duration(days: 5)),
        updatedAt: now,
      ));

      final vm = LibraryViewModel(
        bookRepository: bookRepo,
        loanRepository: loanRepo,
        shelfRepository: shelfRepo,
      );

      // Aguarda emissão dos streams
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(vm.totalCount, 3);
      expect(vm.readingCount, 1);
      expect(vm.readCount, 1);
      expect(vm.wantToReadCount, 1);
      expect(vm.loanedCount, 1);
      expect(vm.overdueCount, 0);

      // Filtro Rápido "Lendo"
      vm.setQuickFilter('reading');
      expect(vm.filteredBooks.length, 1);
      expect(vm.filteredBooks.first.title, 'O Hobbit');

      // Filtro Rápido "Emprestados"
      vm.setQuickFilter('loaned');
      expect(vm.filteredBooks.length, 1);
      expect(vm.filteredBooks.first.title, 'Duna');
    });

    test('aplica busca textual por título e por autor', () async {
      final now = DateTime.now();
      await bookRepo.saveBook(BookModel(
        id: '1',
        title: 'Memórias Póstumas de Brás Cubas',
        author: 'Machado de Assis',
        createdAt: now,
        updatedAt: now,
      ));
      await bookRepo.saveBook(BookModel(
        id: '2',
        title: 'Dom Casmurro',
        author: 'Machado de Assis',
        createdAt: now,
        updatedAt: now,
      ));
      await bookRepo.saveBook(BookModel(
        id: '3',
        title: 'Grande Sertão: Veredas',
        author: 'Guimarães Rosa',
        createdAt: now,
        updatedAt: now,
      ));

      final vm = LibraryViewModel(
        bookRepository: bookRepo,
        loanRepository: loanRepo,
        shelfRepository: shelfRepo,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      vm.setSearchQuery('Machado');
      expect(vm.filteredBooks.length, 2);

      vm.setSearchQuery('Sertão');
      expect(vm.filteredBooks.length, 1);
      expect(vm.filteredBooks.first.title, 'Grande Sertão: Veredas');
    });

    test('aplica filtros avançados combinados (AND)', () async {
      final now = DateTime.now();
      await bookRepo.saveBook(BookModel(
        id: '1',
        title: 'Neuromancer',
        author: 'William Gibson',
        genre: 'Cyberpunk',
        publishedYear: 1984,
        rating: 4.5,
        status: BookStatus.read,
        tags: ['scifi', 'clássico'],
        createdAt: now,
        updatedAt: now,
      ));

      await bookRepo.saveBook(BookModel(
        id: '2',
        title: 'Snow Crash',
        author: 'Neal Stephenson',
        genre: 'Cyberpunk',
        publishedYear: 1992,
        rating: 3.5,
        status: BookStatus.read,
        tags: ['scifi'],
        createdAt: now,
        updatedAt: now,
      ));

      final vm = LibraryViewModel(
        bookRepository: bookRepo,
        loanRepository: loanRepo,
        shelfRepository: shelfRepo,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Filtro de Gênero Cyberpunk + minRating 4.0
      vm.setAdvancedFilters(const AdvancedFilters(
        genre: 'Cyberpunk',
        minRating: 4.0,
      ));

      expect(vm.filteredBooks.length, 1);
      expect(vm.filteredBooks.first.title, 'Neuromancer');
    });

    test('gerencia estantes temáticas e filtra livros por estante', () async {
      final now = DateTime.now();
      await shelfRepo.saveShelf(ShelfModel(
        id: 'shelf-1',
        name: 'Favoritos',
        createdAt: now,
        updatedAt: now,
      ));

      await bookRepo.saveBook(BookModel(
        id: '1',
        title: 'Livro Na Estante',
        author: 'Autor A',
        shelfIds: ['shelf-1'],
        createdAt: now,
        updatedAt: now,
      ));

      await bookRepo.saveBook(BookModel(
        id: '2',
        title: 'Livro Fora',
        author: 'Autor B',
        shelfIds: [],
        createdAt: now,
        updatedAt: now,
      ));

      final vm = LibraryViewModel(
        bookRepository: bookRepo,
        loanRepository: loanRepo,
        shelfRepository: shelfRepo,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(vm.shelves.length, 1);

      vm.setSelectedShelf('shelf-1');
      expect(vm.filteredBooks.length, 1);
      expect(vm.filteredBooks.first.title, 'Livro Na Estante');

      vm.setSelectedShelf(null);
      expect(vm.filteredBooks.length, 2);
    });

    test('ao excluir estante, remove shelfId dos livros sem excluir os livros', () async {
      final now = DateTime.now();
      await shelfRepo.saveShelf(ShelfModel(
        id: 'shelf-del',
        name: 'Temporária',
        createdAt: now,
        updatedAt: now,
      ));

      await bookRepo.saveBook(BookModel(
        id: 'b1',
        title: 'Dom Casmurro',
        author: 'Machado de Assis',
        shelfIds: ['shelf-del', 'shelf-keep'],
        createdAt: now,
        updatedAt: now,
      ));

      final vm = LibraryViewModel(
        bookRepository: bookRepo,
        loanRepository: loanRepo,
        shelfRepository: shelfRepo,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      vm.setSelectedShelf('shelf-del');

      await vm.deleteShelf('shelf-del');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(vm.shelves.isEmpty, isTrue);
      expect(vm.selectedShelfId, isNull);
      expect(vm.totalCount, 1);
      final updatedBook = await bookRepo.getBookById('b1');
      expect(updatedBook, isNotNull);
      expect(updatedBook!.shelfIds, ['shelf-keep']);
    });
  });
}
