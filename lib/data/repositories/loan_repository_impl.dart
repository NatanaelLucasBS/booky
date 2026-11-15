import 'dart:async';
import '../../domain/models/loan_model.dart';
import '../../domain/repositories/loan_repository.dart';
import '../services/storage_service.dart';

/// Implementação da Fonte Única de Verdade (SSOT) para Empréstimos.
class LoanRepositoryImpl implements LoanRepository {
  static const String _collection = 'loans';
  final StorageService _storage;
  final _controller = StreamController<List<LoanModel>>.broadcast();
  List<LoanModel> _cache = [];
  bool _initialized = false;

  LoanRepositoryImpl(this._storage);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final rawList = await _storage.getAll(_collection);
    _cache = rawList.map((e) => LoanModel.fromJson(e)).toList();
    _initialized = true;
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Stream<List<LoanModel>> watchLoans() async* {
    await _ensureInitialized();
    yield List.unmodifiable(_cache);
    yield* _controller.stream;
  }

  @override
  Stream<List<LoanModel>> watchLoansByBook(String bookId) async* {
    await _ensureInitialized();
    yield _cache.where((l) => l.bookId == bookId).toList();
    yield* _controller.stream.map(
      (list) => list.where((l) => l.bookId == bookId).toList(),
    );
  }

  @override
  Future<LoanModel?> getActiveLoanByBook(String bookId) async {
    await _ensureInitialized();
    return _cache.where((l) => l.bookId == bookId && !l.isReturned).firstOrNull;
  }

  @override
  Future<void> saveLoan(LoanModel loan) async {
    await _ensureInitialized();
    await _storage.upsert(_collection, loan.id, loan.toJson());
    final index = _cache.indexWhere((l) => l.id == loan.id);
    if (index >= 0) {
      _cache[index] = loan;
    } else {
      _cache.add(loan);
    }
    _controller.add(List.unmodifiable(_cache));
  }

  @override
  Future<void> deleteLoansByBook(String bookId) async {
    await _ensureInitialized();
    final toRemove = _cache.where((l) => l.bookId == bookId).toList();
    for (final l in toRemove) {
      await _storage.delete(_collection, l.id);
    }
    _cache.removeWhere((l) => l.bookId == bookId);
    _controller.add(List.unmodifiable(_cache));
  }

  void dispose() {
    _controller.close();
  }
}
