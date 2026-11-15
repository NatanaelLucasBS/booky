import '../models/loan_model.dart';

/// Contrato canônico do Repositório de Empréstimos (SSOT).
abstract interface class LoanRepository {
  Stream<List<LoanModel>> watchLoans();
  Stream<List<LoanModel>> watchLoansByBook(String bookId);
  Future<LoanModel?> getActiveLoanByBook(String bookId);
  Future<void> saveLoan(LoanModel loan);
  Future<void> deleteLoansByBook(String bookId);
}
