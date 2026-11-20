import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/services/backup_sync_service.dart';
import '../../../../domain/models/book_model.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/loan_model.dart';
import '../../../../domain/models/shelf_model.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/loan_repository.dart';
import '../../../../domain/repositories/shelf_repository.dart';
import '../../../../domain/use_cases/export_library_use_case.dart';
import '../../../../domain/use_cases/restore_backup_use_case.dart';

/// Filtros avançados combinados para o modal de busca
class AdvancedFilters {
  final String? author;
  final String? genre;
  final int? publishedYear;
  final BookStatus? status;
  final double? minRating;
  final String? shelfId;
  final String? tag;

  const AdvancedFilters({
    this.author,
    this.genre,
    this.publishedYear,
    this.status,
    this.minRating,
    this.shelfId,
    this.tag,
  });

  bool get isEmpty =>
      (author == null || author!.isEmpty) &&
      (genre == null || genre!.isEmpty) &&
      publishedYear == null &&
      status == null &&
      minRating == null &&
      shelfId == null &&
      (tag == null || tag!.isEmpty);

  int get count {
    int c = 0;
    if (author != null && author!.isNotEmpty) c++;
    if (genre != null && genre!.isNotEmpty) c++;
    if (publishedYear != null) c++;
    if (status != null) c++;
    if (minRating != null) c++;
    if (shelfId != null) c++;
    if (tag != null && tag!.isNotEmpty) c++;
    return c;
  }

  AdvancedFilters copyWith({
    String? author,
    String? genre,
    int? publishedYear,
    BookStatus? status,
    double? minRating,
    String? shelfId,
    String? tag,
    bool clearAuthor = false,
    bool clearGenre = false,
    bool clearYear = false,
    bool clearStatus = false,
    bool clearRating = false,
    bool clearShelf = false,
    bool clearTag = false,
  }) {
    return AdvancedFilters(
      author: clearAuthor ? null : (author ?? this.author),
      genre: clearGenre ? null : (genre ?? this.genre),
      publishedYear: clearYear ? null : (publishedYear ?? this.publishedYear),
      status: clearStatus ? null : (status ?? this.status),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      shelfId: clearShelf ? null : (shelfId ?? this.shelfId),
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }
}

// ViewModel da tela da biblioteca
class LibraryViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;
  final LoanRepository _loanRepository;
  final ShelfRepository _shelfRepository;
  final ExportLibraryUseCase? _exportLibraryUseCase;
  final BackupSyncService? _backupSyncService;
  final RestoreBackupUseCase? _restoreBackupUseCase;

  StreamSubscription<List<BookModel>>? _booksSub;
  StreamSubscription<List<LoanModel>>? _loansSub;
  StreamSubscription<List<ShelfModel>>? _shelvesSub;

  List<BookModel> _allBooks = [];
  List<LoanModel> _allLoans = [];
  List<ShelfModel> _allShelves = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _quickFilter = 'all'; // all, reading, read, wantToRead, abandoned, loaned, overdue
  String get quickFilter => _quickFilter;

  String? _selectedShelfId;
  String? get selectedShelfId => _selectedShelfId;

  AdvancedFilters _advancedFilters = const AdvancedFilters();
  AdvancedFilters get advancedFilters => _advancedFilters;

  LibraryViewModel({
    required BookRepository bookRepository,
    required LoanRepository loanRepository,
    required ShelfRepository shelfRepository,
    ExportLibraryUseCase? exportLibraryUseCase,
    BackupSyncService? backupSyncService,
    RestoreBackupUseCase? restoreBackupUseCase,
  })  : _bookRepository = bookRepository,
        _loanRepository = loanRepository,
        _shelfRepository = shelfRepository,
        _exportLibraryUseCase = exportLibraryUseCase,
        _backupSyncService = backupSyncService,
        _restoreBackupUseCase = restoreBackupUseCase {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _booksSub = _bookRepository.watchBooks().listen((books) {
      _allBooks = books;
      _isLoading = false;
      notifyListeners();
    });

    _loansSub = _loanRepository.watchLoans().listen((loans) {
      _allLoans = loans;
      notifyListeners();
    });

    _shelvesSub = _shelfRepository.watchShelves().listen((shelves) {
      _allShelves = shelves;
      notifyListeners();
    });
  }

  List<ShelfModel> get shelves => List.unmodifiable(_allShelves);

  // --- Helpers de Empréstimos por Livro ---
  LoanModel? getActiveLoanForBook(String bookId) {
    return _allLoans.where((l) => l.bookId == bookId && !l.isReturned).firstOrNull;
  }

  bool isBookLoaned(String bookId) {
    return getActiveLoanForBook(bookId) != null;
  }

  bool isBookOverdue(String bookId) {
    final loan = getActiveLoanForBook(bookId);
    return loan != null && loan.isOverdue;
  }

  // --- Contadores Dinâmicos ---
  int get totalCount => _allBooks.length;
  int get readingCount => _allBooks.where((b) => b.status == BookStatus.reading).length;
  int get readCount => _allBooks.where((b) => b.status == BookStatus.read).length;
  int get wantToReadCount => _allBooks.where((b) => b.status == BookStatus.wantToRead).length;
  int get abandonedCount => _allBooks.where((b) => b.status == BookStatus.abandoned).length;
  int get loanedCount => _allBooks.where((b) => isBookLoaned(b.id)).length;
  int get overdueCount => _allBooks.where((b) => isBookOverdue(b.id)).length;

  // --- Ações de Filtro ---
  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setQuickFilter(String filter) {
    _quickFilter = filter;
    notifyListeners();
  }

  void setSelectedShelf(String? shelfId) {
    _selectedShelfId = shelfId;
    notifyListeners();
  }

  void setAdvancedFilters(AdvancedFilters filters) {
    _advancedFilters = filters;
    notifyListeners();
  }

  void clearAdvancedFilters() {
    _advancedFilters = const AdvancedFilters();
    notifyListeners();
  }

  // --- Lista Filtrada ---
  List<BookModel> get filteredBooks {
    return _allBooks.where((book) {
      // 1. Filtro rápido de status ou empréstimo
      if (_quickFilter == 'reading' && book.status != BookStatus.reading) return false;
      if (_quickFilter == 'read' && book.status != BookStatus.read) return false;
      if (_quickFilter == 'wantToRead' && book.status != BookStatus.wantToRead) return false;
      if (_quickFilter == 'abandoned' && book.status != BookStatus.abandoned) return false;
      if (_quickFilter == 'loaned' && !isBookLoaned(book.id)) return false;
      if (_quickFilter == 'overdue' && !isBookOverdue(book.id)) return false;

      // 2. Filtro por estante selecionada na barra rápida
      if (_selectedShelfId != null && !book.shelfIds.contains(_selectedShelfId)) {
        return false;
      }

      // 3. Busca textual por título ou autor
      if (_searchQuery.isNotEmpty) {
        final matchesTitle = book.title.toLowerCase().contains(_searchQuery);
        final matchesAuthor = book.author.toLowerCase().contains(_searchQuery);
        if (!matchesTitle && !matchesAuthor) return false;
      }

      // 4. Filtros Avançados Combinados (AND)
      if (!_advancedFilters.isEmpty) {
        if (_advancedFilters.author != null && _advancedFilters.author!.isNotEmpty) {
          if (!book.author.toLowerCase().contains(_advancedFilters.author!.toLowerCase())) {
            return false;
          }
        }
        if (_advancedFilters.genre != null && _advancedFilters.genre!.isNotEmpty) {
          if (book.genre == null ||
              !book.genre!.toLowerCase().contains(_advancedFilters.genre!.toLowerCase())) {
            return false;
          }
        }
        if (_advancedFilters.publishedYear != null) {
          if (book.publishedYear != _advancedFilters.publishedYear) {
            return false;
          }
        }
        if (_advancedFilters.status != null) {
          if (book.status != _advancedFilters.status) {
            return false;
          }
        }
        if (_advancedFilters.minRating != null) {
          if (book.rating == null || book.rating! < _advancedFilters.minRating!) {
            return false;
          }
        }
        if (_advancedFilters.shelfId != null) {
          if (!book.shelfIds.contains(_advancedFilters.shelfId)) {
            return false;
          }
        }
        if (_advancedFilters.tag != null && _advancedFilters.tag!.isNotEmpty) {
          final target = _advancedFilters.tag!.toLowerCase();
          if (!book.tags.any((t) => t.toLowerCase() == target)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  // --- Operações de Estante Temática ---
  Future<void> createShelf(String name, String? description) async {
    final clean = name.trim();
    if (clean.isEmpty) return;

    final newShelf = ShelfModel(
      id: const Uuid().v4(),
      name: clean,
      description: description?.trim().isEmpty ?? true ? null : description!.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _shelfRepository.saveShelf(newShelf);
  }

  Future<void> updateShelf(ShelfModel shelf, String name, String? description) async {
    final clean = name.trim();
    if (clean.isEmpty) return;

    final updated = shelf.copyWith(
      name: clean,
      description: description?.trim().isEmpty ?? true ? null : description!.trim(),
      updatedAt: DateTime.now(),
    );

    await _shelfRepository.saveShelf(updated);
  }

  Future<void> deleteShelf(String shelfId) async {
    await _shelfRepository.deleteShelf(shelfId);

    final affectedBooks =
        _allBooks.where((b) => b.shelfIds.contains(shelfId)).toList();
    for (final book in affectedBooks) {
      final updatedShelfIds =
          book.shelfIds.where((id) => id != shelfId).toList();
      await _bookRepository.saveBook(
        book.copyWith(
          shelfIds: updatedShelfIds,
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (_selectedShelfId == shelfId) {
      _selectedShelfId = null;
      notifyListeners();
    }
  }

  Future<void> exportLibrary({
    required ExportScope scope,
    required ExportFormat format,
  }) async {
    final useCase = _exportLibraryUseCase;
    if (useCase == null) {
      throw StateError('Serviço de exportação indisponível.');
    }
    await useCase.execute(scope: scope, format: format);
  }

  Future<void> exportBackup() async {
    final service = _backupSyncService;
    if (service == null) {
      throw StateError('Serviço de backup indisponível.');
    }
    await service.exportBackupAndShare();
  }

  Future<int> restoreBackup(String rawJson) async {
    final useCase = _restoreBackupUseCase;
    if (useCase == null) {
      throw StateError('Serviço de restauração indisponível.');
    }
    return useCase.execute(rawJson);
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
    _loansSub?.cancel();
    _shelvesSub?.cancel();
    super.dispose();
  }
}
