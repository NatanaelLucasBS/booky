import 'package:flutter_test/flutter_test.dart';
import 'package:booky/domain/models/app_settings_model.dart';
import 'package:booky/domain/models/book_model.dart';
import 'package:booky/domain/models/enums.dart';
import 'package:booky/domain/models/loan_model.dart';
import 'package:booky/domain/models/note_model.dart';
import 'package:booky/domain/models/reading_session_model.dart';
import 'package:booky/domain/models/shelf_model.dart';

void main() {
  group('Serialização dos modelos (toJson / fromJson)', () {
    test('AppSettingsModel serializa e desserializa corretamente', () {
      final now = DateTime(2026, 11, 15, 14, 30);
      final original = AppSettingsModel(
        annualReadingGoal: 24,
        dailyReminderEnabled: true,
        dailyReminderHour: 21,
        dailyReminderMinute: 15,
        updatedAt: now,
      );

      final json = original.toJson();
      final restored = AppSettingsModel.fromJson(json);

      expect(restored.annualReadingGoal, 24);
      expect(restored.dailyReminderEnabled, isTrue);
      expect(restored.dailyReminderHour, 21);
      expect(restored.dailyReminderMinute, 15);
      expect(restored.updatedAt, now);
    });

    test('BookModel serializa e desserializa todos os campos e calcula getters', () {
      final created = DateTime(2026, 1, 10, 10, 0);
      final started = DateTime(2026, 1, 12, 18, 0);
      final updated = DateTime(2026, 1, 20, 22, 0);

      final original = BookModel(
        id: 'book-123',
        isbn: '9788535914849',
        title: '1984',
        author: 'George Orwell',
        publisher: 'Companhia das Letras',
        publishedYear: 2009,
        genre: 'Distopia',
        synopsis: 'Grande Irmão está de olho em você.',
        coverUrl: 'https://example.com/1984.jpg',
        totalPages: 416,
        currentPage: 208,
        status: BookStatus.reading,
        format: BookFormat.physical,
        rating: 4.5,
        tags: const ['clássico', 'ficção'],
        shelfIds: const ['shelf-1'],
        startedAt: started,
        finishedAt: null,
        createdAt: created,
        updatedAt: updated,
      );

      expect(original.progressPercent, closeTo(0.5, 0.001));
      expect(original.isFinished, isFalse);

      final json = original.toJson();
      final restored = BookModel.fromJson(json);

      expect(restored.id, 'book-123');
      expect(restored.isbn, '9788535914849');
      expect(restored.title, '1984');
      expect(restored.author, 'George Orwell');
      expect(restored.publisher, 'Companhia das Letras');
      expect(restored.publishedYear, 2009);
      expect(restored.genre, 'Distopia');
      expect(restored.synopsis, 'Grande Irmão está de olho em você.');
      expect(restored.coverUrl, 'https://example.com/1984.jpg');
      expect(restored.totalPages, 416);
      expect(restored.currentPage, 208);
      expect(restored.status, BookStatus.reading);
      expect(restored.format, BookFormat.physical);
      expect(restored.rating, 4.5);
      expect(restored.tags, ['clássico', 'ficção']);
      expect(restored.shelfIds, ['shelf-1']);
      expect(restored.startedAt, started);
      expect(restored.finishedAt, isNull);
      expect(restored.createdAt, created);
      expect(restored.updatedAt, updated);
    });

    test('BookModel trata totalPages zero sem NaN em progressPercent', () {
      final now = DateTime.now();
      final book = BookModel(
        id: 'b-zero',
        title: 'Sem Páginas',
        author: 'Autor',
        totalPages: 0,
        currentPage: 10,
        createdAt: now,
        updatedAt: now,
      );

      expect(book.progressPercent, 0.0);
      expect(book.isFinished, isFalse);
    });

    test('ShelfModel serializa e desserializa corretamente', () {
      final now = DateTime(2026, 5, 1, 12, 0);
      final shelf = ShelfModel(
        id: 'shelf-1',
        name: 'Favoritos',
        description: 'Livros 5 estrelas',
        createdAt: now,
        updatedAt: now,
      );

      final restored = ShelfModel.fromJson(shelf.toJson());
      expect(restored.id, 'shelf-1');
      expect(restored.name, 'Favoritos');
      expect(restored.description, 'Livros 5 estrelas');
      expect(restored.createdAt, now);
    });

    test('ReadingSessionModel serializa e gera fallback de dateKey se ausente', () {
      final start = DateTime(2026, 3, 7, 19, 30);
      final session = ReadingSessionModel(
        id: 'sess-1',
        bookId: 'book-1',
        startTime: start,
        durationSeconds: 1800,
        startPage: 10,
        endPage: 35,
        pagesRead: 25,
        dateKey: '2026-03-07',
        updatedAt: start,
      );

      final restored = ReadingSessionModel.fromJson(session.toJson());
      expect(restored.id, 'sess-1');
      expect(restored.pagesRead, 25);
      expect(restored.dateKey, '2026-03-07');

      final withoutDateKey = ReadingSessionModel.fromJson({
        'id': 'sess-2',
        'bookId': 'book-1',
        'startTime': start.toIso8601String(),
        'durationSeconds': 600,
        'startPage': 35,
        'endPage': 45,
        'pagesRead': 10,
      });
      expect(withoutDateKey.dateKey, '2026-03-07');
    });

    test('NoteModel serializa note, quote e review corretamente', () {
      final now = DateTime(2026, 8, 14, 9, 0);
      final quote = NoteModel(
        id: 'note-1',
        bookId: 'book-1',
        type: NoteType.quote,
        chapter: 'Capítulo 4',
        page: 72,
        content: 'Capitu tinha olhos de ressaca.',
        createdAt: now,
        updatedAt: now,
      );

      final restored = NoteModel.fromJson(quote.toJson());
      expect(restored.id, 'note-1');
      expect(restored.type, NoteType.quote);
      expect(restored.chapter, 'Capítulo 4');
      expect(restored.page, 72);
      expect(restored.content, 'Capitu tinha olhos de ressaca.');
    });

    test('LoanModel serializa e desserializa inclusive datas em epoch int', () {
      final loanDate = DateTime(2026, 10, 1);
      final expected = DateTime(2026, 10, 15);
      final loan = LoanModel(
        id: 'loan-1',
        bookId: 'book-1',
        borrowerName: 'João Pedro',
        borrowerContact: '84999990000',
        loanDate: loanDate,
        expectedReturnDate: expected,
        isReturned: false,
        notificationId: 42,
        updatedAt: loanDate,
      );

      final restored = LoanModel.fromJson(loan.toJson());
      expect(restored.id, 'loan-1');
      expect(restored.borrowerName, 'João Pedro');
      expect(restored.borrowerContact, '84999990000');
      expect(restored.notificationId, 42);
      expect(restored.isReturned, isFalse);

      final fromEpoch = LoanModel.fromJson({
        'id': 'loan-2',
        'bookId': 'book-1',
        'borrowerName': 'Maria',
        'borrowerContact': 'maria@ufrn.br',
        'loanDate': loanDate.millisecondsSinceEpoch,
        'expectedReturnDate': expected.millisecondsSinceEpoch,
        'updatedAt': loanDate.millisecondsSinceEpoch,
      });
      expect(fromEpoch.loanDate, loanDate);
      expect(fromEpoch.expectedReturnDate, expected);
    });
  });
}
