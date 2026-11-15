import '../../data/services/notification_service.dart';
import '../models/loan_model.dart';
import '../repositories/loan_repository.dart';

/// Caso de Uso para concluir/devolver um empréstimo ativo.
class ReturnLoanUseCase {
  final LoanRepository _loanRepository;
  final NotificationService _notificationService;

  ReturnLoanUseCase({
    required LoanRepository loanRepository,
    required NotificationService notificationService,
  })  : _loanRepository = loanRepository,
        _notificationService = notificationService;

  Future<LoanModel> execute(LoanModel loan) async {
    final updated = loan.copyWith(
      isReturned: true,
      returnedDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _loanRepository.saveLoan(updated);

    if (loan.notificationId != null) {
      await _notificationService.cancelNotification(loan.notificationId!);
    }

    return updated;
  }
}
