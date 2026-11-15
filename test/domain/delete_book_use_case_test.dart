import 'package:flutter_test/flutter_test.dart';
import 'package:booky/data/repositories/book_repository_impl.dart';
import 'package:booky/data/repositories/loan_repository_impl.dart';
import 'package:booky/data/repositories/note_repository_impl.dart';
import 'package:booky/data/repositories/session_repository_impl.dart';
import 'package:booky/data/services/storage_service.dart';
import 'package:booky/domain/models/book_model.dart';
import 'package:booky/domain/models/enums.dart';
import 'package:booky/domain/models/loan_model.dart';
import 'package:booky/domain/models/note_model.dart';
import 'package:booky/domain/models/reading_session_model.dart';
import 'package:booky/domain/use_cases/delete_book_use_case.dart';

void main() {
  late InMemoryStorageService storage;
  late BookRepositoryImpl bookRepo;
  late NoteRepositoryImpl noteRepo;
  late LoanRepositoryImpl loanRepo;
  late SessionRepositoryImpl sessionRepo;
  late DeleteBookUseCase deleteBookUseCase;

  setUp(() {
    storage = InMemoryStorageService();
    bookRepo = BookRepositoryImpl(storage);
    noteRepo = NoteRepositoryImpl(storage);
    loanRepo = LoanRepositoryImpl(storage);
    sessionRepo = SessionRepositoryImpl(storage);
    deleteBookUseCase = DeleteBookUseCase(
      bookRepository: bookRepo,
      noteRepository: noteRepo,
      loanRepository: loanRepo,
      sessionRepository: sessionRepo,
    );
  });

  test('DeleteBookUseCase remove livro e registros dependentes em cascata sem afetar outros livros', () async {
    final now = DateTime.now();

    // Livro 1 (será removido) e Livro 2 (deve permanecer)
    await bookRepo.saveBook(BookModel(
      id: 'b1',
      title: 'Livro 1',
      author: 'Autor 1',
      createdAt: now,
      updatedAt: now,
    ));
    await bookRepo.saveBook(BookModel(
      id: 'b2',
      title: 'Livro 2',
      author: 'Autor 2',
      createdAt: now,
      updatedAt: now,
    ));

    // Notas de b1 e b2
    await noteRepo.saveNote(NoteModel(
      id: 'n1',
      bookId: 'b1',
      type: NoteType.quote,
      content: 'Citação do livro 1',
      createdAt: now,
      updatedAt: now,
    ));
    await noteRepo.saveNote(NoteModel(
      id: 'n2',
      bookId: 'b2',
      type: NoteType.note,
      content: 'Anotação do livro 2',
      createdAt: now,
      updatedAt: now,
    ));

    // Empréstimos de b1 e b2
    await loanRepo.saveLoan(LoanModel(
      id: 'l1',
      bookId: 'b1',
      borrowerName: 'Amigo A',
      borrowerContact: '1111',
      loanDate: now,
      expectedReturnDate: now.add(const Duration(days: 7)),
      updatedAt: now,
    ));
    await loanRepo.saveLoan(LoanModel(
      id: 'l2',
      bookId: 'b2',
      borrowerName: 'Amigo B',
      borrowerContact: '2222',
      loanDate: now,
      expectedReturnDate: now.add(const Duration(days: 7)),
      updatedAt: now,
    ));

    // Sessões de b1 e b2
    await sessionRepo.addSession(ReadingSessionModel(
      id: 's1',
      bookId: 'b1',
      startTime: now,
      durationSeconds: 600,
      startPage: 0,
      endPage: 15,
      pagesRead: 15,
      dateKey: '2026-11-15',
      updatedAt: now,
    ));
    await sessionRepo.addSession(ReadingSessionModel(
      id: 's2',
      bookId: 'b2',
      startTime: now,
      durationSeconds: 900,
      startPage: 0,
      endPage: 20,
      pagesRead: 20,
      dateKey: '2026-11-15',
      updatedAt: now,
    ));

    // Executa exclusão em cascata de b1
    await deleteBookUseCase.execute('b1');

    expect(await bookRepo.getBookById('b1'), isNull);
    expect(await noteRepo.watchNotesByBook('b1').first, isEmpty);
    expect(await loanRepo.getActiveLoanByBook('b1'), isNull);
    expect(await sessionRepo.getSessionsByBook('b1'), isEmpty);

    // Verifica que b2 permanece intacto
    expect(await bookRepo.getBookById('b2'), isNotNull);
    expect((await noteRepo.watchNotesByBook('b2').first).length, 1);
    expect(await loanRepo.getActiveLoanByBook('b2'), isNotNull);
    expect((await sessionRepo.getSessionsByBook('b2')).length, 1);
  });
}
