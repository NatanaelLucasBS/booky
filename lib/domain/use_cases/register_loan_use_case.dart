import 'package:uuid/uuid.dart';
import '../../data/services/notification_service.dart';
import '../models/loan_model.dart';
import '../repositories/loan_repository.dart';

/// Caso de Uso para registrar empréstimo de um livro.
/// Valida unicidade de empréstimo ativo, persiste no LoanRepository e agenda notificação.
class RegisterLoanUseCase {
  final LoanRepository _loanRepository;
  final NotificationService _notificationService;

  RegisterLoanUseCase({
    required LoanRepository loanRepository,
    required NotificationService notificationService,
  })  : _loanRepository = loanRepository,
        _notificationService = notificationService;

  Future<LoanModel> execute({
    required String bookId,
    required String bookTitle,
    required String borrowerName,
    required String borrowerContact,
    required DateTime loanDate,
    required DateTime expectedReturnDate,
  }) async {
    final cleanBorrower = borrowerName.trim();
    if (cleanBorrower.isEmpty) {
      throw ArgumentError('O nome do amigo é obrigatório para registrar o empréstimo.');
    }

    final loanDay = DateTime(loanDate.year, loanDate.month, loanDate.day);
    final returnDay = DateTime(
      expectedReturnDate.year,
      expectedReturnDate.month,
      expectedReturnDate.day,
    );
    if (returnDay.isBefore(loanDay)) {
      throw ArgumentError('A data prevista de devolução não pode ser anterior à data do empréstimo.');
    }

    // Valida se já existe empréstimo ativo para este livro
    final activeLoan = await _loanRepository.getActiveLoanByBook(bookId);
    if (activeLoan != null) {
      throw StateError('Este livro já possui um empréstimo ativo para "${activeLoan.borrowerName}".');
    }

    final id = const Uuid().v4();
    final notificationId = id.hashCode.abs() & 0x7FFFFFFF;

    final loan = LoanModel(
      id: id,
      bookId: bookId,
      borrowerName: cleanBorrower,
      borrowerContact: borrowerContact.trim(),
      loanDate: loanDate,
      expectedReturnDate: expectedReturnDate,
      notificationId: notificationId,
      updatedAt: DateTime.now(),
    );

    await _loanRepository.saveLoan(loan);

    // Agenda lembrete de devolução
    await _notificationService.scheduleLoanReturnReminder(
      id: notificationId,
      bookTitle: bookTitle,
      borrowerName: cleanBorrower,
      expectedReturnDate: expectedReturnDate,
    );

    return loan;
  }
}
