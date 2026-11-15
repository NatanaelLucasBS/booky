import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:booky/domain/models/app_settings_model.dart';
import 'package:booky/domain/models/book_model.dart';
import 'package:booky/domain/models/enums.dart';
import 'package:booky/domain/models/loan_model.dart';
import 'package:booky/domain/models/reading_session_model.dart';
import 'package:booky/domain/repositories/book_repository.dart';
import 'package:booky/domain/repositories/loan_repository.dart';
import 'package:booky/domain/repositories/session_repository.dart';
import 'package:booky/domain/repositories/settings_repository.dart';
import 'package:booky/domain/use_cases/get_dashboard_stats_use_case.dart';
import 'package:booky/features/home/presentation/viewmodels/home_viewmodel.dart';

import '../tracker/tracker_viewmodel_test.dart';

class MockLoanRepositoryForHome implements LoanRepository {
  final _loans = <LoanModel>[];
  final _controller = StreamController<List<LoanModel>>.broadcast();

  void emit(List<LoanModel> loans) {
    _loans.clear();
    _loans.addAll(loans);
    _controller.add(List.unmodifiable(_loans));
  }

  @override
  Stream<List<LoanModel>> watchLoans() {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(_loans)));
    return _controller.stream;
  }

  @override
  Stream<List<LoanModel>> watchLoansByBook(String bookId) {
    return _controller.stream.map((list) => list.where((l) => l.bookId == bookId).toList());
  }

  @override
  Future<LoanModel?> getActiveLoanByBook(String bookId) async {
    return _loans.where((l) => l.bookId == bookId && !l.isReturned).firstOrNull;
  }

  @override
  Future<void> saveLoan(LoanModel loan) async {
    _loans.removeWhere((l) => l.id == loan.id);
    _loans.add(loan);
    _controller.add(List.unmodifiable(_loans));
  }

  @override
  Future<void> deleteLoansByBook(String bookId) async {
    _loans.removeWhere((l) => l.bookId == bookId);
    _controller.add(List.unmodifiable(_loans));
  }
}

class MockSettingsRepositoryForHome implements SettingsRepository {
  AppSettingsModel _settings = AppSettingsModel.initial().copyWith(annualReadingGoal: 10);
  final _controller = StreamController<AppSettingsModel>.broadcast();

  @override
  Stream<AppSettingsModel> watchSettings() {
    scheduleMicrotask(() => _controller.add(_settings));
    return _controller.stream;
  }

  @override
  Future<AppSettingsModel> getSettings() async => _settings;

  @override
  Future<void> updateAnnualGoal(int goal) async {
    _settings = _settings.copyWith(annualReadingGoal: goal);
    _controller.add(_settings);
  }

  @override
  Future<void> updateDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    _settings = _settings.copyWith(
      dailyReminderEnabled: enabled,
      dailyReminderHour: hour,
      dailyReminderMinute: minute,
    );
    _controller.add(_settings);
  }
}

void main() {
  late MockBookRepository bookRepo;
  late MockSessionRepository sessionRepo;
  late MockLoanRepositoryForHome loanRepo;
  late MockSettingsRepositoryForHome settingsRepo;
  late GetDashboardStatsUseCase getDashboardStatsUseCase;

  setUp(() {
    bookRepo = MockBookRepository();
    sessionRepo = MockSessionRepository();
    loanRepo = MockLoanRepositoryForHome();
    settingsRepo = MockSettingsRepositoryForHome();

    getDashboardStatsUseCase = GetDashboardStatsUseCase(
      bookRepository: bookRepo,
      sessionRepository: sessionRepo,
      loanRepository: loanRepo,
      settingsRepository: settingsRepo,
    );

    final now = DateTime.now();
    bookRepo.emit([
      BookModel(
        id: 'b1',
        title: 'Livro Em Andamento',
        author: 'Autor 1',
        totalPages: 400,
        currentPage: 200,
        status: BookStatus.reading,
        createdAt: now,
        updatedAt: now,
      ),
      BookModel(
        id: 'b2',
        title: 'Livro Concluído',
        author: 'Autor 2',
        totalPages: 300,
        currentPage: 300,
        status: BookStatus.read,
        finishedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  });

  test('GetDashboardStatsUseCase agrega estatísticas de livros e sessões corretamente', () async {
    final stats = await getDashboardStatsUseCase.execute();

    expect(stats.currentBook?.id, equals('b1'));
    expect(stats.totalBooksRead, equals(1));
    expect(stats.booksReadThisYear, equals(1));
    expect(stats.annualGoal, equals(10));
    expect(stats.annualGoalProgress, equals(0.1));
    expect(stats.monthlyStats.length, equals(6));
  });

  test('HomeViewModel gerencia alternancia de graficos e atualizacao de metas', () async {
    final vm = HomeViewModel(
      bookRepository: bookRepo,
      sessionRepository: sessionRepo,
      loanRepository: loanRepo,
      settingsRepository: settingsRepo,
      getDashboardStatsUseCase: getDashboardStatsUseCase,
    );

    await pumpEventQueue();

    expect(vm.isLoading, isFalse);
    expect(vm.stats?.currentBook?.id, equals('b1'));
    expect(vm.selectedMetric, equals(ChartMetric.pages));

    vm.setChartMetric(ChartMetric.books);
    expect(vm.selectedMetric, equals(ChartMetric.books));

    await vm.updateAnnualGoal(20);
    final updatedSettings = await settingsRepo.getSettings();
    expect(updatedSettings.annualReadingGoal, equals(20));

    expect(vm.dismissOverdueAlert, isFalse);
    vm.dismissAlert();
    expect(vm.dismissOverdueAlert, isTrue);

    vm.dispose();
  });
}
