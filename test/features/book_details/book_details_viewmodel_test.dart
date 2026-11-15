import 'package:flutter_test/flutter_test.dart';
import 'package:booky/data/services/storage_service.dart';
import 'package:booky/data/services/notification_service.dart';
import 'package:booky/data/services/ocr_service.dart';
import 'package:booky/data/repositories/book_repository_impl.dart';
import 'package:booky/data/repositories/loan_repository_impl.dart';
import 'package:booky/data/repositories/note_repository_impl.dart';
import 'package:booky/data/repositories/session_repository_impl.dart';
import 'package:booky/data/repositories/shelf_repository_impl.dart';
import 'package:booky/domain/models/book_model.dart';
import 'package:booky/domain/models/enums.dart';
import 'package:booky/domain/use_cases/delete_book_use_case.dart';
import 'package:booky/domain/use_cases/register_loan_use_case.dart';
import 'package:booky/domain/use_cases/return_loan_use_case.dart';
import 'package:booky/features/book_details/presentation/viewmodels/book_details_viewmodel.dart';

class FakeNotificationService extends NotificationService {
  final List<int> scheduled = [];
  final List<int> cancelled = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleLoanReturnReminder({
    required int id,
    required String bookTitle,
    required String borrowerName,
    required DateTime expectedReturnDate,
  }) async {
    scheduled.add(id);
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelled.add(id);
  }
}

void main() {
  late InMemoryStorageService storage;
  late BookRepositoryImpl bookRepo;
  late NoteRepositoryImpl noteRepo;
  late LoanRepositoryImpl loanRepo;
  late SessionRepositoryImpl sessionRepo;
  late ShelfRepositoryImpl shelfRepo;
  late FakeNotificationService notificationService;
  late RegisterLoanUseCase registerLoanUseCase;
  late ReturnLoanUseCase returnLoanUseCase;
  late DeleteBookUseCase deleteBookUseCase;

  setUp(() {
    storage = InMemoryStorageService();
    bookRepo = BookRepositoryImpl(storage);
    noteRepo = NoteRepositoryImpl(storage);
    loanRepo = LoanRepositoryImpl(storage);
    sessionRepo = SessionRepositoryImpl(storage);
    shelfRepo = ShelfRepositoryImpl(storage);
    notificationService = FakeNotificationService();

    registerLoanUseCase = RegisterLoanUseCase(
      loanRepository: loanRepo,
      notificationService: notificationService,
    );

    returnLoanUseCase = ReturnLoanUseCase(
      loanRepository: loanRepo,
      notificationService: notificationService,
    );

    deleteBookUseCase = DeleteBookUseCase(
      bookRepository: bookRepo,
      noteRepository: noteRepo,
      loanRepository: loanRepo,
      sessionRepository: sessionRepo,
    );
  });

  group('RegisterLoanUseCase & ReturnLoanUseCase', () {
    test('registra emprestimo com sucesso e agenda notificacao', () async {
      final now = DateTime.now();
      final loan = await registerLoanUseCase.execute(
        bookId: 'b1',
        bookTitle: 'Dom Casmurro',
        borrowerName: 'Mariana',
        borrowerContact: '9999-9999',
        loanDate: now,
        expectedReturnDate: now.add(const Duration(days: 7)),
      );

      expect(loan.borrowerName, 'Mariana');
      expect(loan.isReturned, isFalse);
      expect(notificationService.scheduled.length, 1);
      expect(notificationService.scheduled.first, loan.notificationId);

      final saved = await loanRepo.getActiveLoanByBook('b1');
      expect(saved, isNotNull);
      expect(saved!.id, loan.id);
    });

    test('rejeita emprestimo se ja houver outro ativo para o mesmo livro', () async {
      final now = DateTime.now();
      await registerLoanUseCase.execute(
        bookId: 'b1',
        bookTitle: 'Dom Casmurro',
        borrowerName: 'Mariana',
        borrowerContact: '9999-9999',
        loanDate: now,
        expectedReturnDate: now.add(const Duration(days: 7)),
      );

      expect(
        () => registerLoanUseCase.execute(
          bookId: 'b1',
          bookTitle: 'Dom Casmurro',
          borrowerName: 'Carlos',
          borrowerContact: '8888-8888',
          loanDate: now,
          expectedReturnDate: now.add(const Duration(days: 7)),
        ),
        throwsStateError,
      );
    });

    test('marca devolucao e cancela notificacao', () async {
      final now = DateTime.now();
      final loan = await registerLoanUseCase.execute(
        bookId: 'b1',
        bookTitle: 'Dom Casmurro',
        borrowerName: 'Mariana',
        borrowerContact: '9999-9999',
        loanDate: now,
        expectedReturnDate: now.add(const Duration(days: 7)),
      );

      final returned = await returnLoanUseCase.execute(loan);
      expect(returned.isReturned, isTrue);
      expect(returned.returnedDate, isNotNull);
      expect(notificationService.cancelled, contains(loan.notificationId));

      final active = await loanRepo.getActiveLoanByBook('b1');
      expect(active, isNull);
    });
  });

  group('BookDetailsViewModel', () {
    test('gerencia notas, citacoes e resenha independentemente', () async {
      final now = DateTime.now();
      await bookRepo.saveBook(BookModel(
        id: 'b1',
        title: 'O Silmarillion',
        author: 'J.R.R. Tolkien',
        createdAt: now,
        updatedAt: now,
      ));

      final vm = BookDetailsViewModel(
        bookId: 'b1',
        bookRepository: bookRepo,
        noteRepository: noteRepo,
        loanRepository: loanRepo,
        shelfRepository: shelfRepo,
        ocrService: OcrService(),
        registerLoanUseCase: registerLoanUseCase,
        returnLoanUseCase: returnLoanUseCase,
        deleteBookUseCase: deleteBookUseCase,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(vm.book?.title, 'O Silmarillion');
      expect(vm.plainNotes, isEmpty);

      // Salva Anotação
      await vm.saveNote(
        type: NoteType.note,
        content: 'Reflexão sobre a criação de Arda.',
        chapter: 'Ainulindalë',
      );

      // Salva Citação
      await vm.saveNote(
        type: NoteType.quote,
        content: 'Havia Eru, o Único, que em Arda é chamado de Ilúvatar.',
        page: 3,
      );

      // Salva Resenha
      await vm.saveNote(
        type: NoteType.review,
        content: 'Obra monumental da mitologia tolkieniana.',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(vm.plainNotes.length, 1);
      expect(vm.quotes.length, 1);
      expect(vm.review, isNotNull);
      expect(vm.review!.content, 'Obra monumental da mitologia tolkieniana.');
    });

    test('atualiza avaliacao e status do livro', () async {
      final now = DateTime.now();
      await bookRepo.saveBook(BookModel(
        id: 'b1',
        title: 'Livro Teste',
        author: 'Autor',
        totalPages: 200,
        createdAt: now,
        updatedAt: now,
      ));

      final vm = BookDetailsViewModel(
        bookId: 'b1',
        bookRepository: bookRepo,
        noteRepository: noteRepo,
        loanRepository: loanRepo,
        shelfRepository: shelfRepo,
        ocrService: OcrService(),
        registerLoanUseCase: registerLoanUseCase,
        returnLoanUseCase: returnLoanUseCase,
        deleteBookUseCase: deleteBookUseCase,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await vm.updateRating(5.0);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(vm.book?.rating, 5.0);

      await vm.updateStatus(BookStatus.read);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(vm.book?.status, BookStatus.read);
      expect(vm.book?.currentPage, 200);
      expect(vm.book?.finishedAt, isNotNull);
    });
  });
}
