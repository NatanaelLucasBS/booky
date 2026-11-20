import '../models/note_model.dart';

// Repositório de anotações, citações e resenhas
abstract interface class NoteRepository {
  Stream<List<NoteModel>> watchNotesByBook(String bookId);
  Future<void> saveNote(NoteModel note);
  Future<void> deleteNote(String noteId);
  Future<void> deleteNotesByBook(String bookId);
}
