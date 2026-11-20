import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/services/book_api_service.dart';
import '../../../../domain/models/book_model.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/shelf_model.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/shelf_repository.dart';

// ViewModel da tela de adicionar e editar livro
class AddBookViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;
  final ShelfRepository _shelfRepository;
  final BookApiService _bookApiService;
  final BookModel? initialBook;

  AddBookViewModel({
    required BookRepository bookRepository,
    required ShelfRepository shelfRepository,
    required BookApiService bookApiService,
    this.initialBook,
  })  : _bookRepository = bookRepository,
        _shelfRepository = shelfRepository,
        _bookApiService = bookApiService {
    _initFromExisting();
  }

  // --- Estado da UI ---
  int _activeMode = 0; // 0: Scanner, 1: Manual
  int get activeMode => _activeMode;

  bool _isLookingUp = false;
  bool get isLookingUp => _isLookingUp;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // --- Campos do Formulário ---
  String _isbn = '';
  String get isbn => _isbn;

  String _title = '';
  String get title => _title;

  String _author = '';
  String get author => _author;

  String? _publisher;
  String? get publisher => _publisher;

  int? _publishedYear;
  int? get publishedYear => _publishedYear;

  int _totalPages = 0;
  int get totalPages => _totalPages;

  String? _genre;
  String? get genre => _genre;

  String? _synopsis;
  String? get synopsis => _synopsis;

  String? _coverUrl;
  String? get coverUrl => _coverUrl;

  BookStatus _status = BookStatus.wantToRead;
  BookStatus get status => _status;

  BookFormat _format = BookFormat.physical;
  BookFormat get format => _format;

  List<String> _selectedShelfIds = [];
  List<String> get selectedShelfIds => List.unmodifiable(_selectedShelfIds);

  List<String> _tags = [];
  List<String> get tags => List.unmodifiable(_tags);

  List<ShelfModel> _availableShelves = [];
  List<ShelfModel> get availableShelves => List.unmodifiable(_availableShelves);

  void _initFromExisting() {
    if (initialBook != null) {
      _activeMode = 1; // Modo manual preenchido
      _isbn = initialBook!.isbn ?? '';
      _title = initialBook!.title;
      _author = initialBook!.author;
      _publisher = initialBook!.publisher;
      _publishedYear = initialBook!.publishedYear;
      _totalPages = initialBook!.totalPages;
      _genre = initialBook!.genre;
      _synopsis = initialBook!.synopsis;
      _coverUrl = initialBook!.coverUrl;
      _status = initialBook!.status;
      _format = initialBook!.format;
      _selectedShelfIds = List.from(initialBook!.shelfIds);
      _tags = List.from(initialBook!.tags);
    }
  }

  /// Inicializa e observa estantes cadastradas
  Future<void> loadShelves() async {
    try {
      _availableShelves = await _shelfRepository.getShelves();
      notifyListeners();
    } catch (_) {}
  }

  void setMode(int mode) {
    if (_activeMode != mode) {
      _activeMode = mode;
      notifyListeners();
    }
  }

  void setTitle(String value) {
    _title = value.trim();
  }

  void setAuthor(String value) {
    _author = value.trim();
  }

  void setIsbn(String value) {
    _isbn = value.trim();
  }

  void setPublisher(String? value) {
    _publisher = value?.trim().isEmpty ?? true ? null : value!.trim();
  }

  void setPublishedYear(int? value) {
    _publishedYear = value;
  }

  void setTotalPages(int value) {
    _totalPages = value < 0 ? 0 : value;
  }

  void setGenre(String? value) {
    _genre = value?.trim().isEmpty ?? true ? null : value!.trim();
  }

  void setSynopsis(String? value) {
    _synopsis = value?.trim().isEmpty ?? true ? null : value!.trim();
  }

  void setCoverUrl(String? value) {
    _coverUrl = value?.trim().isEmpty ?? true ? null : value!.trim();
  }

  void setStatus(BookStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void setFormat(BookFormat newFormat) {
    _format = newFormat;
    notifyListeners();
  }

  void toggleShelf(String shelfId) {
    if (_selectedShelfIds.contains(shelfId)) {
      _selectedShelfIds.remove(shelfId);
    } else {
      _selectedShelfIds.add(shelfId);
    }
    notifyListeners();
  }

  void addTag(String tag) {
    final clean = tag.trim().toLowerCase();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      _tags.add(clean);
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    if (_tags.remove(tag)) {
      notifyListeners();
    }
  }

  /// Cria uma nova estante temática
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
    _availableShelves.add(newShelf);
    _selectedShelfIds.add(newShelf.id);
    notifyListeners();
  }

  /// Valida se um código lido pelo scanner/input tem formato ISBN-10 ou ISBN-13.
  bool isValidIsbn(String rawIsbn) => BookApiService.isValidIsbn(rawIsbn);

  /// Consulta metadados de livro via BookApiService (Open Library API)
  Future<bool> lookupByIsbn(String rawIsbn) async {
    final clean = BookApiService.normalizeIsbn(rawIsbn);
    if (!BookApiService.isValidIsbn(clean)) {
      _errorMessage = 'Código ISBN inválido. Digite 10 ou 13 dígitos.';
      notifyListeners();
      return false;
    }

    _isLookingUp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _bookApiService.lookupBookByIsbn(clean);
      if (result == null) {
        _errorMessage = 'Nenhum livro encontrado para o ISBN informado.';
        _isLookingUp = false;
        notifyListeners();
        return false;
      }

      // Preenche dados retornados
      _isbn = result.isbn;
      _title = result.title;
      _author = result.author;
      _publisher = result.publisher;
      _publishedYear = result.publishedYear;
      _totalPages = result.totalPages;
      _genre = result.genre;
      _synopsis = result.synopsis;
      _coverUrl = result.coverUrl;

      // Transita para o modo manual preenchido para revisão
      _activeMode = 1;
      _isLookingUp = false;
      _successMessage = 'Livro localizado com sucesso!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLookingUp = false;
      notifyListeners();
      return false;
    }
  }

  /// Salva livro no BookRepository
  Future<bool> saveBook() async {
    if (_title.trim().isEmpty) {
      _errorMessage = 'O título do livro é obrigatório.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final id = initialBook?.id ?? const Uuid().v4();

      DateTime? startedAt = initialBook?.startedAt;
      if (_status == BookStatus.reading && startedAt == null) {
        startedAt = now;
      } else if (_status == BookStatus.wantToRead) {
        startedAt = null;
      }

      DateTime? finishedAt = initialBook?.finishedAt;
      int currentPage = initialBook?.currentPage ?? 0;
      if (_status == BookStatus.read) {
        finishedAt ??= now;
        if (_totalPages > 0) {
          currentPage = _totalPages;
        }
      } else if (_status == BookStatus.wantToRead) {
        finishedAt = null;
        currentPage = 0;
      } else {
        if (initialBook?.status == BookStatus.read) {
          finishedAt = null;
        }
        if (_totalPages > 0 && currentPage > _totalPages) {
          currentPage = _totalPages;
        }
      }

      final bookToSave = BookModel(
        id: id,
        isbn: _isbn.isEmpty ? null : _isbn,
        title: _title,
        author: _author.isEmpty ? 'Autor Desconhecido' : _author,
        publisher: _publisher,
        publishedYear: _publishedYear,
        genre: _genre,
        synopsis: _synopsis,
        coverUrl: _coverUrl,
        totalPages: _totalPages,
        currentPage: currentPage,
        status: _status,
        format: _format,
        rating: initialBook?.rating,
        tags: _tags,
        shelfIds: _selectedShelfIds,
        startedAt: startedAt,
        finishedAt: finishedAt,
        createdAt: initialBook?.createdAt ?? now,
        updatedAt: now,
      );

      await _bookRepository.saveBook(bookToSave);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao salvar livro: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  bool _disposed = false;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
