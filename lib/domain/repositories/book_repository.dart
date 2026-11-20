import '../models/book_model.dart';

// Repositório de livros
abstract interface class BookRepository {
  Stream<List<BookModel>> watchBooks();
  Stream<BookModel?> watchBookById(String bookId);
  Future<List<BookModel>> getBooks();
  Future<BookModel?> getBookById(String bookId);
  Future<void> saveBook(BookModel book);
  Future<void> deleteBook(String bookId);
}
