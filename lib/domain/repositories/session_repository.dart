import '../models/reading_session_model.dart';

/// Contrato canônico do Repositório de Sessões de Leitura (SSOT).
abstract interface class SessionRepository {
  Stream<List<ReadingSessionModel>> watchSessions();
  Stream<List<ReadingSessionModel>> watchSessionsByBook(String bookId);
  Future<List<ReadingSessionModel>> getSessionsByBook(String bookId);
  Future<void> addSession(ReadingSessionModel session);
  Future<void> deleteSessionsByBook(String bookId);
}
