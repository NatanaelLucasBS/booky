import '../../domain/models/app_settings_model.dart';
import '../../domain/models/book_model.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/loan_model.dart';
import '../../domain/models/reading_session_model.dart';
import '../repositories/book_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/settings_repository.dart';

/// Modelo de dados consolidado com as estatísticas do Dashboard.
class DashboardStats {
  final BookModel? currentBook;
  final List<BookModel> currentReadingBooks;
  final int totalBooksRead;
  final int totalPagesReadThisYear;
  final int totalPagesReadThisMonth;
  final int annualGoal;
  final int booksReadThisYear;
  final double annualGoalProgress;
  final List<LoanModel> overdueLoans;
  final List<MonthlyReadingStat> monthlyStats;

  const DashboardStats({
    required this.currentBook,
    required this.currentReadingBooks,
    required this.totalBooksRead,
    required this.totalPagesReadThisYear,
    required this.totalPagesReadThisMonth,
    required this.annualGoal,
    required this.booksReadThisYear,
    required this.annualGoalProgress,
    required this.overdueLoans,
    required this.monthlyStats,
  });
}

class MonthlyReadingStat {
  final int year;
  final int month;
  final String label; // Ex: 'Jan', 'Fev'
  final int pagesRead;
  final int booksFinished;

  const MonthlyReadingStat({
    required this.year,
    required this.month,
    required this.label,
    required this.pagesRead,
    required this.booksFinished,
  });
}

/// UseCase orquestrador do Dashboard (Slide 23 e 27 da Aula 24 - Arquitetura Recomendada).
/// Repositórios nunca dependem entre si; UseCases agregam múltiplos repositórios.
class GetDashboardStatsUseCase {
  final BookRepository _bookRepository;
  final SessionRepository _sessionRepository;
  final LoanRepository _loanRepository;
  final SettingsRepository _settingsRepository;

  const GetDashboardStatsUseCase({
    required BookRepository bookRepository,
    required SessionRepository sessionRepository,
    required LoanRepository loanRepository,
    required SettingsRepository settingsRepository,
  })  : _bookRepository = bookRepository,
        _sessionRepository = sessionRepository,
        _loanRepository = loanRepository,
        _settingsRepository = settingsRepository;

  static const List<String> _monthNames = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];

  Future<DashboardStats> execute() async {
    final books = await _bookRepository.getBooks();
    final sessions = await _sessionRepository.watchSessions().first;
    final loans = await _loanRepository.watchLoans().first;
    final settings = await _settingsRepository.getSettings();

    return aggregate(
      books: books,
      sessions: sessions,
      loans: loans,
      settings: settings,
    );
  }

  DashboardStats aggregate({
    required List<BookModel> books,
    required List<ReadingSessionModel> sessions,
    required List<LoanModel> loans,
    required AppSettingsModel settings,
  }) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 1. Livros em andamento
    final readingBooks = books.where((b) => b.status == BookStatus.reading).toList();
    final currentBook = readingBooks.firstOrNull;

    // 2. Livros lidos no ano e total
    final readBooks = books.where((b) => b.status == BookStatus.read).toList();
    final totalBooksRead = readBooks.length;
    final booksReadThisYear = readBooks.where((b) {
      final finished = b.finishedAt;
      return finished != null && finished.year == currentYear;
    }).length;

    // 3. Páginas lidas no ano e no mês
    int pagesThisYear = 0;
    int pagesThisMonth = 0;
    for (final s in sessions) {
      if (s.startTime.year == currentYear) {
        pagesThisYear += s.pagesRead;
        if (s.startTime.month == currentMonth) {
          pagesThisMonth += s.pagesRead;
        }
      }
    }

    // 4. Meta de leitura anual
    final annualGoal = settings.annualReadingGoal > 0 ? settings.annualReadingGoal : 12;
    final annualGoalProgress = (booksReadThisYear / annualGoal).clamp(0.0, 1.0);

    // 5. Empréstimos em atraso
    final overdueLoans = loans.where((l) => l.isOverdue).toList();

    // 6. Série temporal dos últimos 6 meses
    final List<MonthlyReadingStat> monthlyStats = [];
    for (int i = 5; i >= 0; i--) {
      // Subtrair i meses a partir do mês atual
      final targetDate = DateTime(now.year, now.month - i, 1);
      final y = targetDate.year;
      final m = targetDate.month;
      final label = _monthNames[m - 1];

      int monthPages = 0;
      for (final s in sessions) {
        if (s.startTime.year == y && s.startTime.month == m) {
          monthPages += s.pagesRead;
        }
      }

      int monthBooks = 0;
      for (final b in readBooks) {
        final f = b.finishedAt;
        if (f != null && f.year == y && f.month == m) {
          monthBooks++;
        }
      }

      monthlyStats.add(MonthlyReadingStat(
        year: y,
        month: m,
        label: label,
        pagesRead: monthPages,
        booksFinished: monthBooks,
      ));
    }

    return DashboardStats(
      currentBook: currentBook,
      currentReadingBooks: readingBooks,
      totalBooksRead: totalBooksRead,
      totalPagesReadThisYear: pagesThisYear,
      totalPagesReadThisMonth: pagesThisMonth,
      annualGoal: annualGoal,
      booksReadThisYear: booksReadThisYear,
      annualGoalProgress: annualGoalProgress,
      overdueLoans: overdueLoans,
      monthlyStats: monthlyStats,
    );
  }
}
