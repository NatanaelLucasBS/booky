import '../../data/services/notification_service.dart';
import '../repositories/book_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/note_repository.dart';
import '../repositories/session_repository.dart';

/// Caso de Uso para excluir um livro e seus registros dependentes em cascata
/// sem acoplar repositórios entre si (Slide 23 da Aula 24).
class DeleteBookUseCase {
  final BookRepository _bookRepository;
  final NoteRepository _noteRepository;
  final LoanRepository _loanRepository;
  final SessionRepository _sessionRepository;
  final NotificationService? _notificationService;

  DeleteBookUseCase({
    required BookRepository bookRepository,
    required NoteRepository noteRepository,
    required LoanRepository loanRepository,
    required SessionRepository sessionRepository,
    NotificationService? notificationService,
  })  : _bookRepository = bookRepository,
        _noteRepository = noteRepository,
        _loanRepository = loanRepository,
        _sessionRepository = sessionRepository,
        _notificationService = notificationService;

  Future<void> execute(String bookId) async {
    final activeLoan = await _loanRepository.getActiveLoanByBook(bookId);
    if (activeLoan?.notificationId != null) {
      await _notificationService?.cancelNotification(activeLoan!.notificationId!);
    }
    await _noteRepository.deleteNotesByBook(bookId);
    await _loanRepository.deleteLoansByBook(bookId);
    await _sessionRepository.deleteSessionsByBook(bookId);
    await _bookRepository.deleteBook(bookId);
  }
}
