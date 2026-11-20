import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../data/services/notification_service.dart';
import '../../../../domain/models/app_settings_model.dart';
import '../../../../domain/models/book_model.dart';
import '../../../../domain/models/loan_model.dart';
import '../../../../domain/models/reading_session_model.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/loan_repository.dart';
import '../../../../domain/repositories/session_repository.dart';
import '../../../../domain/repositories/settings_repository.dart';
import '../../../../domain/use_cases/get_dashboard_stats_use_case.dart';

enum ChartMetric {
  pages,
  books;

  String get label => switch (this) {
        ChartMetric.pages => 'Páginas Lidas',
        ChartMetric.books => 'Livros Lidos',
      };
}

// ViewModel da tela inicial (Dashboard)
class HomeViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;
  final SessionRepository _sessionRepository;
  final LoanRepository _loanRepository;
  final SettingsRepository _settingsRepository;
  final GetDashboardStatsUseCase _getDashboardStatsUseCase;
  final NotificationService? _notificationService;

  StreamSubscription<List<BookModel>>? _booksSub;
  StreamSubscription<List<ReadingSessionModel>>? _sessionsSub;
  StreamSubscription<List<LoanModel>>? _loansSub;
  StreamSubscription<AppSettingsModel>? _settingsSub;

  List<BookModel> _books = [];
  List<ReadingSessionModel> _sessions = [];
  List<LoanModel> _loans = [];
  AppSettingsModel _settings = AppSettingsModel.initial();
  AppSettingsModel get settings => _settings;

  DashboardStats? _stats;
  DashboardStats? get stats => _stats;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ChartMetric _selectedMetric = ChartMetric.pages;
  ChartMetric get selectedMetric => _selectedMetric;

  bool _dismissOverdueAlert = false;
  bool get dismissOverdueAlert => _dismissOverdueAlert;

  HomeViewModel({
    required BookRepository bookRepository,
    required SessionRepository sessionRepository,
    required LoanRepository loanRepository,
    required SettingsRepository settingsRepository,
    required GetDashboardStatsUseCase getDashboardStatsUseCase,
    NotificationService? notificationService,
  })  : _bookRepository = bookRepository,
        _sessionRepository = sessionRepository,
        _loanRepository = loanRepository,
        _settingsRepository = settingsRepository,
        _getDashboardStatsUseCase = getDashboardStatsUseCase,
        _notificationService = notificationService {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _booksSub = _bookRepository.watchBooks().listen((books) {
      _books = books;
      _recalculateStats();
    });

    _sessionsSub = _sessionRepository.watchSessions().listen((sessions) {
      _sessions = sessions;
      _recalculateStats();
    });

    _loansSub = _loanRepository.watchLoans().listen((loans) {
      _loans = loans;
      _recalculateStats();
    });

    _settingsSub = _settingsRepository.watchSettings().listen((settings) {
      _settings = settings;
      _recalculateStats();
    });
  }

  void _recalculateStats() {
    _stats = _getDashboardStatsUseCase.aggregate(
      books: _books,
      sessions: _sessions,
      loans: _loans,
      settings: _settings,
    );
    _isLoading = false;
    notifyListeners();
  }

  void setChartMetric(ChartMetric metric) {
    if (_selectedMetric != metric) {
      _selectedMetric = metric;
      notifyListeners();
    }
  }

  void dismissAlert() {
    _dismissOverdueAlert = true;
    notifyListeners();
  }

  Future<void> updateAnnualGoal(int newGoal) async {
    if (newGoal <= 0) return;
    await _settingsRepository.updateAnnualGoal(newGoal);
  }

  Future<void> updateDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await _settingsRepository.updateDailyReminder(
      enabled: enabled,
      hour: hour,
      minute: minute,
    );
    if (enabled) {
      await _notificationService?.scheduleDailyReadingReminder(
        hour: hour,
        minute: minute,
      );
    } else {
      await _notificationService?.cancelDailyReadingReminder();
    }
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _booksSub?.cancel();
    _sessionsSub?.cancel();
    _loansSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }
}
