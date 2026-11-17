import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/services/ocr_service.dart';
import '../../../../domain/models/book_model.dart';
import '../../../../domain/models/enums.dart';
import '../../../../domain/models/loan_model.dart';
import '../../../../domain/models/note_model.dart';
import '../../../../domain/models/shelf_model.dart';
import '../../../../domain/repositories/book_repository.dart';
import '../../../../domain/repositories/loan_repository.dart';
import '../../../../domain/repositories/note_repository.dart';
import '../../../../domain/repositories/shelf_repository.dart';
import '../../../../domain/use_cases/delete_book_use_case.dart';
import '../../../../domain/use_cases/register_loan_use_case.dart';
import '../../../../domain/use_cases/return_loan_use_case.dart';

/// ViewModel para a tela de Detalhes do Livro, Empréstimos e Diário com OCR.
/// Relação 1:1 com BookDetailsScreen (Slide 15 da Aula 24).
class BookDetailsViewModel extends ChangeNotifier {
  final String bookId;
  final BookRepository _bookRepository;
  final NoteRepository _noteRepository;
  final LoanRepository _loanRepository;
  final ShelfRepository _shelfRepository;
  final OcrService _ocrService;
  final RegisterLoanUseCase _registerLoanUseCase;
  final ReturnLoanUseCase _returnLoanUseCase;
  final DeleteBookUseCase _deleteBookUseCase;

  StreamSubscription<BookModel?>? _bookSub;
  StreamSubscription<List<NoteModel>>? _notesSub;
  StreamSubscription<List<LoanModel>>? _loansSub;
  StreamSubscription<List<ShelfModel>>? _shelvesSub;

  BookModel? _book;
  BookModel? get book => _book;

  List<NoteModel> _notes = [];
  List<LoanModel> _loans = [];
  List<ShelfModel> _shelves = [];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  BookDetailsViewModel({
    required this.bookId,
    required BookRepository bookRepository,
    required NoteRepository noteRepository,
    required LoanRepository loanRepository,
    required ShelfRepository shelfRepository,
    required OcrService ocrService,
    required RegisterLoanUseCase registerLoanUseCase,
    required ReturnLoanUseCase returnLoanUseCase,
    required DeleteBookUseCase deleteBookUseCase,
  })  : _bookRepository = bookRepository,
        _noteRepository = noteRepository,
        _loanRepository = loanRepository,
        _shelfRepository = shelfRepository,
        _ocrService = ocrService,
        _registerLoanUseCase = registerLoanUseCase,
        _returnLoanUseCase = returnLoanUseCase,
        _deleteBookUseCase = deleteBookUseCase {
    _initSubscriptions();
  }

  void _initSubscriptions() {
    _bookSub = _bookRepository.watchBookById(bookId).listen((b) {
      _book = b;
      _isLoading = false;
      notifyListeners();
    });

    _notesSub = _noteRepository.watchNotesByBook(bookId).listen((n) {
      _notes = n;
      notifyListeners();
    });

    _loansSub = _loanRepository.watchLoansByBook(bookId).listen((l) {
      _loans = l;
      notifyListeners();
    });

    _shelvesSub = _shelfRepository.watchShelves().listen((s) {
      _shelves = s;
      notifyListeners();
    });
  }

  // --- Empréstimos ---
  LoanModel? get activeLoan => _loans.where((l) => !l.isReturned).firstOrNull;
  bool get isLoaned => activeLoan != null;
  bool get isOverdue => activeLoan?.isOverdue ?? false;
  List<LoanModel> get returnedLoans => _loans.where((l) => l.isReturned).toList();

  // --- Diário de Leitura por Tipo ---
  List<NoteModel> get plainNotes =>
      _notes.where((n) => n.type == NoteType.note).toList();

  List<NoteModel> get quotes =>
      _notes.where((n) => n.type == NoteType.quote).toList();

  NoteModel? get review =>
      _notes.where((n) => n.type == NoteType.review).firstOrNull;

  List<ShelfModel> get bookShelves {
    if (_book == null) return [];
    return _shelves.where((s) => _book!.shelfIds.contains(s.id)).toList();
  }

  // --- Ações do Livro ---
  Future<void> updateRating(double newRating) async {
    if (_book == null) return;
    final updated = _book!.copyWith(rating: newRating, updatedAt: DateTime.now());
    _book = updated;
    notifyListeners();
    await _bookRepository.saveBook(updated);
  }

  Future<void> updateStatus(BookStatus newStatus) async {
    if (_book == null) return;
    final now = DateTime.now();

    DateTime? startedAt = _book!.startedAt;
    if (newStatus == BookStatus.reading && startedAt == null) {
      startedAt = now;
    }

    DateTime? finishedAt = _book!.finishedAt;
    int currentPage = _book!.currentPage;
    if (newStatus == BookStatus.read) {
      finishedAt = now;
      if (_book!.totalPages > 0) currentPage = _book!.totalPages;
    } else if (_book!.status == BookStatus.read) {
      finishedAt = null;
    }

    final updated = _book!.copyWith(
      status: newStatus,
      startedAt: startedAt,
      finishedAt: finishedAt,
      currentPage: currentPage,
      updatedAt: now,
    );
    _book = updated;
    notifyListeners();
    await _bookRepository.saveBook(updated);
  }

  // --- Ações de Notas / Citações / Resenha ---
  Future<void> saveNote({
    required NoteType type,
    required String content,
    String? chapter,
    int? page,
    String? noteId,
  }) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;

    final id = noteId ?? const Uuid().v4();
    final note = NoteModel(
      id: id,
      bookId: bookId,
      type: type,
      chapter: chapter?.trim().isEmpty ?? true ? null : chapter!.trim(),
      page: page,
      content: cleanContent,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _noteRepository.saveNote(note);
    _successMessage = '${type.label} salva com sucesso!';
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    await _noteRepository.deleteNote(noteId);
    notifyListeners();
  }

  /// Extrai texto por OCR via câmera ou galeria usando OcrService
  Future<String?> extractTextFromOcr({required ImageSource source}) async {
    try {
      return await _ocrService.extractTextFromImage(source: source);
    } catch (e) {
      _errorMessage = 'Falha no reconhecimento de texto por OCR: $e';
      notifyListeners();
      return null;
    }
  }

  // --- Ações de Empréstimo ---
  Future<bool> registerLoan({
    required String borrowerName,
    required String borrowerContact,
    required DateTime loanDate,
    required DateTime expectedReturnDate,
  }) async {
    if (_book == null) return false;

    try {
      await _registerLoanUseCase.execute(
        bookId: bookId,
        bookTitle: _book!.title,
        borrowerName: borrowerName,
        borrowerContact: borrowerContact,
        loanDate: loanDate,
        expectedReturnDate: expectedReturnDate,
      );
      _successMessage = 'Empréstimo registrado com sucesso!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('ArgumentError: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> returnLoan() async {
    final current = activeLoan;
    if (current == null) return false;

    try {
      await _returnLoanUseCase.execute(current);
      _successMessage = 'Livro marcado como devolvido!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao processar devolução: $e';
      notifyListeners();
      return false;
    }
  }

  // --- Exclusão do Livro em Cascata ---
  Future<bool> deleteBook() async {
    try {
      await _deleteBookUseCase.execute(bookId);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir livro: $e';
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
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
    _bookSub?.cancel();
    _notesSub?.cancel();
    _loansSub?.cancel();
    _shelvesSub?.cancel();
    super.dispose();
  }
}
