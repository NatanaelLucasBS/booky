import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:booky/domain/models/book_model.dart';
import 'package:booky/domain/models/enums.dart';
import 'package:booky/domain/models/reading_session_model.dart';
import 'package:booky/domain/repositories/book_repository.dart';
import 'package:booky/domain/repositories/session_repository.dart';
import 'package:booky/domain/use_cases/save_reading_session_use_case.dart';
import 'package:booky/features/tracker/presentation/viewmodels/tracker_viewmodel.dart';

class MockBookRepository implements BookRepository {
  final _books = <BookModel>[];
  final _controller = StreamController<List<BookModel>>.broadcast();

  void emit(List<BookModel> books) {
    _books.clear();
    _books.addAll(books);
    _controller.add(List.unmodifiable(_books));
  }

  @override
  Stream<List<BookModel>> watchBooks() {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(_books)));
    return _controller.stream;
  }

  @override
  Future<List<BookModel>> getBooks() async => getAllBooks();

  @override
  Stream<BookModel?> watchBookById(String id) {
    return _controller.stream.map((list) => list.where((b) => b.id == id).firstOrNull);
  }

  @override
  Future<List<BookModel>> getAllBooks() async => List.unmodifiable(_books);

  @override
  Future<BookModel?> getBookById(String id) async {
    return _books.where((b) => b.id == id).firstOrNull;
  }

  @override
  Future<void> saveBook(BookModel book) async {
    _books.removeWhere((b) => b.id == book.id);
    _books.add(book);
    _controller.add(List.unmodifiable(_books));
  }

  @override
  Future<void> deleteBook(String id) async {
    _books.removeWhere((b) => b.id == id);
    _controller.add(List.unmodifiable(_books));
  }

  @override
  Stream<List<BookModel>> watchBooksByStatus(BookStatus status) => throw UnimplementedError();

  @override
  Stream<List<BookModel>> watchBooksByShelf(String shelfId) => throw UnimplementedError();
}

class MockSessionRepository implements SessionRepository {
  final _sessions = <ReadingSessionModel>[];
  final _controller = StreamController<List<ReadingSessionModel>>.broadcast();

  @override
  Future<void> addSession(ReadingSessionModel session) => saveSession(session);

  @override
  Stream<List<ReadingSessionModel>> watchSessions() {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(_sessions)));
    return _controller.stream;
  }

  @override
  Stream<List<ReadingSessionModel>> watchSessionsByBook(String bookId) {
    scheduleMicrotask(() {
      final filtered = _sessions.where((s) => s.bookId == bookId).toList();
      _controller.add(filtered);
    });
    return _controller.stream;
  }

  @override
  Future<List<ReadingSessionModel>> getAllSessions() async => List.unmodifiable(_sessions);

  @override
  Future<List<ReadingSessionModel>> getSessionsByBook(String bookId) async {
    return _sessions.where((s) => s.bookId == bookId).toList();
  }

  @override
  Future<void> saveSession(ReadingSessionModel session) async {
    _sessions.add(session);
    _controller.add(_sessions.where((s) => s.bookId == session.bookId).toList());
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> deleteSessionsByBook(String bookId) async {
    _sessions.removeWhere((s) => s.bookId == bookId);
  }

  @override
  Stream<List<ReadingSessionModel>> watchAllSessions() => throw UnimplementedError();
}

void main() {
  late MockBookRepository bookRepo;
  late MockSessionRepository sessionRepo;
  late SaveReadingSessionUseCase saveUseCase;
  late BookModel testBook;

  setUp(() {
    bookRepo = MockBookRepository();
    sessionRepo = MockSessionRepository();
    saveUseCase = SaveReadingSessionUseCase(
      bookRepository: bookRepo,
      sessionRepository: sessionRepo,
    );

    testBook = BookModel(
      id: 'book-1',
      title: 'O Nome do Vento',
      author: 'Patrick Rothfuss',
      totalPages: 600,
      currentPage: 300,
      status: BookStatus.reading,
      format: BookFormat.physical,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    bookRepo.emit([testBook]);
  });

  test('TrackerViewModel inicializa com livro e pagina atuais', () async {
    final vm = TrackerViewModel(
      initialBookId: 'book-1',
      bookRepository: bookRepo,
      sessionRepository: sessionRepo,
      saveReadingSessionUseCase: saveUseCase,
    );

    await pumpEventQueue();

    expect(vm.selectedBook?.id, equals('book-1'));
    expect(vm.currentPage, equals(300));
    expect(vm.startPage, equals(300));
    expect(vm.isRunning, isFalse);
    expect(vm.currentPercent, equals(0.5));
    vm.dispose();
  });

  test('TrackerViewModel incrementa, decrementa e ajusta paginas', () async {
    final vm = TrackerViewModel(
      initialBookId: 'book-1',
      bookRepository: bookRepo,
      sessionRepository: sessionRepo,
      saveReadingSessionUseCase: saveUseCase,
    );
    await pumpEventQueue();

    vm.incrementPage();
    expect(vm.currentPage, equals(301));
    expect(vm.pagesReadThisSession, equals(1));

    vm.decrementPage();
    expect(vm.currentPage, equals(300));

    vm.setPercent(75.0);
    expect(vm.currentPage, equals(450));
    expect(vm.pagesReadThisSession, equals(150));
    vm.dispose();
  });

  test('TrackerViewModel salva sessao com sucesso e atualiza progresso', () async {
    final vm = TrackerViewModel(
      initialBookId: 'book-1',
      bookRepository: bookRepo,
      sessionRepository: sessionRepo,
      saveReadingSessionUseCase: saveUseCase,
    );
    await pumpEventQueue();

    vm.setPage(350);
    final success = await vm.finishAndSaveSession();
    expect(success, isTrue);

    final savedBook = await bookRepo.getBookById('book-1');
    expect(savedBook?.currentPage, equals(350));
    expect(savedBook?.status, equals(BookStatus.reading));

    final sessions = await sessionRepo.getSessionsByBook('book-1');
    expect(sessions.length, equals(1));
    expect(sessions.first.pagesRead, equals(50));
    vm.dispose();
  });
}
