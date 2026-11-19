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

    test('converte corretamente entre ISBN-13 e ISBN-10', () {
      final isbn10 = BookApiService.convertIsbn13ToIsbn10('9788532511010');
      expect(isbn10, '8532511015');

      final isbn13 = BookApiService.convertIsbn10ToIsbn13('8532511015');
      expect(isbn13, '9788532511010');
    });

    test('extrai páginas de texto e normaliza URL de capa para HTTPS', () {
      expect(BookApiService.extractPagesFromText('328 p.'), 328);
      expect(BookApiService.extractPagesFromText('xii, 256 pages ; 21 cm'), 256);
      expect(BookApiService.extractPagesFromText('312 páginas'), 312);
      expect(BookApiService.extractPagesFromText('280'), 280);
      expect(BookApiService.extractPagesFromText('1 v.'), 0);
      expect(
        BookApiService.normalizeCoverUrl('http://covers.openlibrary.org/b/id/42-L.jpg'),
        'https://covers.openlibrary.org/b/id/42-L.jpg',
      );
      expect(
        BookApiService.normalizeCoverUrl('//covers.openlibrary.org/b/id/42-L.jpg'),
        'https://covers.openlibrary.org/b/id/42-L.jpg',
      );
    });
  });

  group('BookApiService - Consulta Exclusiva Open Library (Mockada)', () {
    test('retorna metadados consolidados a partir da Open Library Books API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'openlibrary.org' && request.url.path == '/api/books') {
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
              'notes': 'Edição brasileira ilustrada.',
              'cover': {
                'large': 'http://covers.openlibrary.org/b/id/1-L.jpg',
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
      expect(result.synopsis, 'Edição brasileira ilustrada.');
      expect(result.totalPages, 224);
      expect(result.coverUrl, 'https://covers.openlibrary.org/b/id/1-L.jpg');
    });

    test('retorna null quando Open Library não encontra o ISBN em nenhum endpoint', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/books') {
          return http.Response('{}', 200);
        }
        if (request.url.path == '/search.json') {
          return http.Response(json.encode({'numFound': 0, 'docs': []}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = BookApiService(client: mockClient);
      final result = await service.lookupBookByIsbn('9788532511010');

      expect(result, isNull);
    });

    test('enriquece sinopse via Edition/Works API (/isbn + /works) e páginas via Search API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/books' &&
            request.url.queryParameters['bibkeys'] == 'ISBN:9788532511010') {
          return http.Response(
            json.encode({
              'ISBN:9788532511010': {
                'title': 'Duna',
                'authors': [
                  {'name': 'Frank Herbert'}
                ],
                'pagination': 'xii, 680 p.',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/isbn/9788532511010.json') {
          return http.Response(
            json.encode({
              'title': 'Duna',
              'works': [
                {'key': '/works/OL893415W'}
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/works/OL893415W.json') {
          return http.Response(
            json.encode({
              'description': {'value': 'A saga épica do planeta Arrakis.'},
              'subjects': ['Ficção Científica'],
            }),
            200,
          );
        }
        if (request.url.path == '/search.json' &&
            request.url.queryParameters['isbn'] == '9788532511010') {
          return http.Response(
            json.encode({
              'numFound': 1,
              'docs': [
                {
                  'title': 'Duna',
                  'author_name': ['Frank Herbert'],
                  'cover_i': 998877,
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = BookApiService(client: mockClient);
      final result = await service.lookupBookByIsbn('9788532511010');

      expect(result, isNotNull);
      expect(result!.title, 'Duna');
      expect(result.author, 'Frank Herbert');
      expect(result.totalPages, 680);
      expect(result.synopsis, 'A saga épica do planeta Arrakis.');
      expect(result.genre, 'Ficção Científica');
      expect(result.coverUrl, 'https://covers.openlibrary.org/b/id/998877-L.jpg');
    });

    test('recupera capa via Open Library Covers API quando outros endpoints não retornam imagem', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/books' &&
            request.url.queryParameters['bibkeys'] == 'ISBN:9788532511010') {
          return http.Response(
            json.encode({
              'ISBN:9788532511010': {
                'title': 'Dom Casmurro',
                'authors': [
                  {'name': 'Machado de Assis'}
                ],
                'number_of_pages': 256,
                'notes': 'Clássico da literatura brasileira.',
              },
            }),
            200,
          );
        }
        if (request.url.host == 'covers.openlibrary.org' &&
            request.url.path == '/b/isbn/9788532511010-L.jpg') {
          return http.Response.bytes(List<int>.filled(1000, 1), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = BookApiService(client: mockClient);
      final result = await service.lookupBookByIsbn('9788532511010');

      expect(result, isNotNull);
      expect(result!.title, 'Dom Casmurro');
      expect(result.totalPages, 256);
      expect(result.coverUrl, 'https://covers.openlibrary.org/b/isbn/9788532511010-L.jpg');
    });
  });
}
