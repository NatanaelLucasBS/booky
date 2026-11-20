import 'package:flutter_test/flutter_test.dart';
import 'package:booky/domain/models/loan_model.dart';

void main() {
  group('LoanModel.isOverdue - Verificação de atraso', () {
    test('retorna false quando empréstimo está no prazo futuro', () {
      final now = DateTime.now();
      final loan = LoanModel(
        id: 'l1',
        bookId: 'b1',
        borrowerName: 'Amigo 1',
        borrowerContact: '84999999999',
        loanDate: now.subtract(const Duration(days: 2)),
        expectedReturnDate: now.add(const Duration(days: 5)),
        isReturned: false,
        updatedAt: now,
      );

      expect(loan.isOverdue, isFalse);
    });

    test('retorna false quando vence hoje (válido até 23:59:59 do dia previsto)', () {
      final now = DateTime.now();
      final todayMorning = DateTime(now.year, now.month, now.day, 8, 0);
      final loan = LoanModel(
        id: 'l2',
        bookId: 'b1',
        borrowerName: 'Amigo 2',
        borrowerContact: '84999999999',
        loanDate: todayMorning.subtract(const Duration(days: 7)),
        expectedReturnDate: todayMorning,
        isReturned: false,
        updatedAt: now,
      );

      expect(loan.isOverdue, isFalse);
    });

    test('retorna true quando data prevista já passou e não foi devolvido', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final loan = LoanModel(
        id: 'l3',
        bookId: 'b1',
        borrowerName: 'Amigo 3',
        borrowerContact: '84999999999',
        loanDate: now.subtract(const Duration(days: 10)),
        expectedReturnDate: yesterday,
        isReturned: false,
        updatedAt: now,
      );

      expect(loan.isOverdue, isTrue);
    });

    test('retorna false quando data prevista já passou mas livro já foi devolvido', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final loan = LoanModel(
        id: 'l4',
        bookId: 'b1',
        borrowerName: 'Amigo 4',
        borrowerContact: '84999999999',
        loanDate: now.subtract(const Duration(days: 10)),
        expectedReturnDate: yesterday,
        returnedDate: now,
        isReturned: true,
        updatedAt: now,
      );

      expect(loan.isOverdue, isFalse);
    });
  });
}
