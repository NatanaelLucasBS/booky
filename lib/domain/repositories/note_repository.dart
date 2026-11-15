import '../models/note_model.dart';

/// Contrato canônico do Repositório de Anotações, Citações e Resenhas (SSOT).
abstract interface class NoteRepository {
  Stream<List<NoteModel>> watchNotesByBook(String bookId);
  Future<void> saveNote(NoteModel note);
  Future<void> deleteNote(String noteId);
  Future<void> deleteNotesByBook(String bookId);
}
