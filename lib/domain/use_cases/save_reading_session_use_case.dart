import 'dart:math';
import 'package:uuid/uuid.dart';

import '../models/book_model.dart';
import '../models/enums.dart';
import '../models/reading_session_model.dart';
import '../repositories/book_repository.dart';
import '../repositories/session_repository.dart';

/// Caso de Uso para salvar uma sessão de leitura.
/// Orquestra SessionRepository e BookRepository sem acoplamento mútuo.
class SaveReadingSessionUseCase {
  final SessionRepository _sessionRepository;
  final BookRepository _bookRepository;

  SaveReadingSessionUseCase({
    required SessionRepository sessionRepository,
    required BookRepository bookRepository,
  })  : _sessionRepository = sessionRepository,
        _bookRepository = bookRepository;

  Future<ReadingSessionModel> execute({
    required BookModel book,
    required DateTime startTime,
    required int durationSeconds,
    required int startPage,
    required int endPage,
  }) async {
    final now = DateTime.now();
    final pagesRead = max(0, endPage - startPage);
    final dateKey =
        '${startTime.year.toString().padLeft(4, '0')}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';

    final session = ReadingSessionModel(
      id: const Uuid().v4(),
      bookId: book.id,
      startTime: startTime,
      durationSeconds: max(0, durationSeconds),
      startPage: startPage,
      endPage: endPage,
      pagesRead: pagesRead,
      dateKey: dateKey,
      updatedAt: now,
    );

    // 1. Grava a sessão no SessionRepository
    await _sessionRepository.addSession(session);

    // 2. Atualiza estado e progresso no BookRepository
    DateTime? startedAt = book.startedAt ?? startTime;
    DateTime? finishedAt = book.finishedAt;
    BookStatus status = book.status;

    if (book.totalPages > 0 && endPage >= book.totalPages) {
      status = BookStatus.read;
      finishedAt = now;
    } else if (book.status == BookStatus.wantToRead && endPage > 0) {
      status = BookStatus.reading;
    }

    final updatedBook = book.copyWith(
      currentPage: endPage,
      status: status,
      startedAt: startedAt,
      finishedAt: finishedAt,
      updatedAt: now,
    );

    await _bookRepository.saveBook(updatedBook);

    return session;
  }
}
