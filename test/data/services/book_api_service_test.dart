import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:booky/data/services/book_api_service.dart';

void main() {
  group('BookApiService - Validação e Normalização', () {
    test('normaliza ISBN removendo traços e espaços', () {
      expect(BookApiService.normalizeIsbn('978-85-325-1101-0'), '9788532511010');
      expect(BookApiService.normalizeIsbn(' 85 325 1101 5 '), '8532511015');
      expect(BookApiService.normalizeIsbn('0-19-852663-x'), '019852663X');
    });

    test('valida corretamente ISBN-10 e ISBN-13', () {
      expect(BookApiService.isValidIsbn('978-85-325-1101-0'), isTrue);
      expect(BookApiService.isValidIsbn('019852663X'), isTrue);
      expect(BookApiService.isValidIsbn('123'), isFalse);
      expect(BookApiService.isValidIsbn('invalid-isbn'), isFalse);
    });

    test('lança BookApiException se ISBN for inválido', () async {
      final service = BookApiService();
      expect(
        () => service.lookupBookByIsbn('123'),
        throwsA(isA<BookApiException>()),
      );
    });
  });

  group('BookApiService - Consulta Mockada', () {
    test('retorna metadados consolidados a partir da Google Books API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          final body = json.encode({
            'totalItems': 1,
            'items': [
              {
                'volumeInfo': {
                  'title': 'Dom Casmurro',
                  'authors': ['Machado de Assis'],
                  'publisher': 'Editora Garnier',
                  'publishedDate': '1899',
                  'categories': ['Ficção Brasileira'],
                  'description': 'A história de Bentinho e Capitu.',
                  'pageCount': 256,
                  'imageLinks': {
                    'thumbnail': 'http://books.google.com/thumbnail.jpg',
                  },
                },
              },
            ],
          });
          return http.Response(body, 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = BookApiService(client: mockClient);
      final result = await service.lookupBookByIsbn('9788532511010');

      expect(result, isNotNull);
      expect(result!.title, 'Dom Casmurro');
      expect(result.author, 'Machado de Assis');
      expect(result.publisher, 'Editora Garnier');
      expect(result.publishedYear, 1899);
      expect(result.genre, 'Ficção Brasileira');
      expect(result.synopsis, 'A história de Bentinho e Capitu.');
      expect(result.totalPages, 256);
      expect(result.coverUrl, 'https://books.google.com/thumbnail.jpg');
    });

    test('executa fallback na Open Library API quando Google Books retorna vazio', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          return http.Response(json.encode({'totalItems': 0}), 200);
        }
        if (request.url.host == 'openlibrary.org') {
          final body = json.encode({
            'ISBN:9788532511010': {
              'title': 'Harry Potter e a Pedra Filosofal',
              'authors': [
                {'name': 'J.K. Rowling'}
              ],
              'publishers': [
                {'name': 'Rocco'}
              ],
              'publish_date': '2000',
              'number_of_pages': 224,
              'subjects': [
                {'name': 'Fantasia'}
              ],
              'cover': {
                'large': 'https://covers.openlibrary.org/b/id/1-L.jpg',
              },
            },
          });
          return http.Response(body, 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = BookApiService(client: mockClient);
      final result = await service.lookupBookByIsbn('9788532511010');

      expect(result, isNotNull);
      expect(result!.title, 'Harry Potter e a Pedra Filosofal');
      expect(result.author, 'J.K. Rowling');
      expect(result.publisher, 'Rocco');
      expect(result.publishedYear, 2000);
      expect(result.genre, 'Fantasia');
      expect(result.totalPages, 224);
      expect(result.coverUrl, 'https://covers.openlibrary.org/b/id/1-L.jpg');
    });
  });
}
