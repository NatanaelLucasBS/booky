import 'dart:async';
import 'package:flutter/widgets.dart';

import '../../../../domain/models/book_model.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/reading_session_model.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/session_repository.dart';
import '../../../../domain/use_cases/save_reading_session_use_case.dart';

/// ViewModel para a tela de Rastreamento de Leitura e Cronômetro (relação 1:1 com ReadingTrackerScreen).
/// Slide 15 e 18 da Aula 24 (Arquitetura Flutter).
class TrackerViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final BookRepository _bookRepository;
  final SessionRepository _sessionRepository;
  final SaveReadingSessionUseCase _saveReadingSessionUseCase;
  final String? initialBookId;

  StreamSubscription<List<BookModel>>? _booksSub;
  StreamSubscription<List<ReadingSessionModel>>? _sessionsSub;

  BookModel? _selectedBook;
  BookModel? get selectedBook => _selectedBook;

  List<BookModel> _availableBooks = [];
  List<BookModel> get availableBooks => List.unmodifiable(_availableBooks);

  List<ReadingSessionModel> _sessions = [];
  List<ReadingSessionModel> get sessions => List.unmodifiable(_sessions);

  // --- Cronômetro com Precisão em Segundo Plano ---
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  DateTime? _runningSince;
  int _accumulatedSeconds = 0;
  DateTime? _sessionStartTime;
  Timer? _ticker;

  int get currentSeconds {
    if (_isRunning && _runningSince != null) {
      return _accumulatedSeconds + DateTime.now().difference(_runningSince!).inSeconds;
    }
    return _accumulatedSeconds;
  }

  // --- Progresso de Páginas ---
  int _startPage = 0;
  int get startPage => _startPage;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  TrackerViewModel({
    this.initialBookId,
    required BookRepository bookRepository,
    required SessionRepository sessionRepository,
    required SaveReadingSessionUseCase saveReadingSessionUseCase,
  })  : _bookRepository = bookRepository,
        _sessionRepository = sessionRepository,
        _saveReadingSessionUseCase = saveReadingSessionUseCase {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRunning) {
      notifyListeners();
    }
  }

  void _init() {
    _booksSub = _bookRepository.watchBooks().listen((books) {
      _availableBooks = books;
      if (_selectedBook == null) {
        if (initialBookId != null) {
          _selectedBook = books.where((b) => b.id == initialBookId).firstOrNull;
        }
        _selectedBook ??= books.where((b) => b.status == BookStatus.reading).firstOrNull ??
            books.firstOrNull;

        if (_selectedBook != null) {
          _startPage = _selectedBook!.currentPage;
          _currentPage = _selectedBook!.currentPage;
          _subscribeSessions(_selectedBook!.id);
        }
      } else {
        final updated = books.where((b) => b.id == _selectedBook!.id).firstOrNull;
        if (updated != null) {
          _selectedBook = updated;
        }
      }
      notifyListeners();
    });
  }

  void _subscribeSessions(String bookId) {
    _sessionsSub?.cancel();
    _sessionsSub = _sessionRepository.watchSessionsByBook(bookId).listen((s) {
      _sessions = s;
      notifyListeners();
    });
  }

  void selectBook(BookModel book) {
    if (_isRunning) pauseTimer();
    _selectedBook = book;
    _startPage = book.currentPage;
    _currentPage = book.currentPage;
    _accumulatedSeconds = 0;
    _runningSince = null;
    _sessionStartTime = null;
    _subscribeSessions(book.id);
    notifyListeners();
  }

  // --- Controles do Cronômetro ---
  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _runningSince = DateTime.now();
    _sessionStartTime ??= DateTime.now();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });

    notifyListeners();
  }

  void pauseTimer() {
    if (!_isRunning) return;
    if (_runningSince != null) {
      _accumulatedSeconds += DateTime.now().difference(_runningSince!).inSeconds;
    }
    _isRunning = false;
    _runningSince = null;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void resetTimer() {
    pauseTimer();
    _accumulatedSeconds = 0;
    _sessionStartTime = null;
    notifyListeners();
  }

  // --- Controles de Página e Porcentagem ---
  void setPage(int page) {
    if (_selectedBook == null) return;
    final total = _selectedBook!.totalPages > 0 ? _selectedBook!.totalPages : 99999;
    _currentPage = page.clamp(0, total);
    notifyListeners();
  }

  void incrementPage() {
    setPage(_currentPage + 1);
  }

  void decrementPage() {
    setPage(_currentPage - 1);
  }

  void setPercent(double percent) {
    if (_selectedBook == null || _selectedBook!.totalPages <= 0) return;
    final pct = percent.clamp(0.0, 100.0);
    final page = ((pct / 100.0) * _selectedBook!.totalPages).round();
    setPage(page);
  }

  double get currentPercent {
    if (_selectedBook == null || _selectedBook!.totalPages <= 0) return 0.0;
    return (_currentPage / _selectedBook!.totalPages).clamp(0.0, 1.0);
  }

  int get pagesReadThisSession => (_currentPage - _startPage).clamp(0, 99999);

  // --- Velocidade e Estimativa de Conclusão ---
  double get pagesPerHour {
    int totalPages = 0;
    int totalSeconds = 0;

    for (final s in _sessions) {
      totalPages += s.pagesRead;
      totalSeconds += s.durationSeconds;
    }

    if (totalSeconds >= 60 && totalPages > 0) {
      return (totalPages / (totalSeconds / 3600.0));
    }

    // Ritmo padrão estimado para leitores (30 pág/hora)
    return 30.0;
  }

  Duration? get remainingTime {
    if (_selectedBook == null ||
        _selectedBook!.totalPages <= 0 ||
        _currentPage >= _selectedBook!.totalPages) {
      return null;
    }

    final speed = pagesPerHour;
    if (speed <= 0) return null;

    final remainingPages = _selectedBook!.totalPages - _currentPage;
    final hours = remainingPages / speed;
    return Duration(seconds: (hours * 3600).round());
  }

  // --- Histórico Diário Agrupado ---
  Map<String, List<ReadingSessionModel>> get dailyGroupedSessions {
    final map = <String, List<ReadingSessionModel>>{};
    for (final s in _sessions) {
      map.putIfAbsent(s.dateKey, () => []).add(s);
    }
    return map;
  }

  // --- Salvar Sessão ---
  Future<bool> finishAndSaveSession() async {
    if (_selectedBook == null) return false;

    pauseTimer();
    final duration = _accumulatedSeconds;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final startTime = _sessionStartTime ?? DateTime.now().subtract(Duration(seconds: duration));

      await _saveReadingSessionUseCase.execute(
        book: _selectedBook!,
        startTime: startTime,
        durationSeconds: duration,
        startPage: _startPage,
        endPage: _currentPage,
      );

      _startPage = _currentPage;
      _accumulatedSeconds = 0;
      _sessionStartTime = null;
      _isSaving = false;
      _successMessage = 'Sessão de leitura registrada com sucesso!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao salvar sessão: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _ticker?.cancel();
    _booksSub?.cancel();
    _sessionsSub?.cancel();
    super.dispose();
  }
}
