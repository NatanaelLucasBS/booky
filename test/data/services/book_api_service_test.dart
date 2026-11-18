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

    test('enriquece dados via BrasilAPI quando Google Books não possui páginas ou capa', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          // Google Books acha o livro mas não tem páginas nem capa
          final body = json.encode({
            'totalItems': 1,
            'items': [
              {
                'volumeInfo': {
                  'title': 'O Alquimista',
                  'authors': ['Paulo Coelho'],
                  'publisher': 'Paralela',
                  'publishedDate': '1988',
                  'description': 'Um clássico brasileiro.',
                  'pageCount': 0, // sem páginas
                },
              },
            ],
          });
          return http.Response(body, 200);
        }
        if (request.url.host == 'brasilapi.com.br') {
          // BrasilAPI fornece páginas, ano e editora
          final body = json.encode({
            'isbn': '9788532511010',
            'title': 'O Alquimista',
            'authors': ['Paulo Coelho'],
            'publisher': 'Paralela',
            'synopsis': 'Sinopse oficial CBL.',
            'year': 1988,
            'page_count': 208,
            'subjects': ['Ficção'],
            'cover_url': 'https://brasilapi.com.br/covers/alquimista.jpg',
          });
          return http.Response(body, 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = BookApiService(client: mockClient);
      final result = await service.lookupBookByIsbn('9788532511010');

      expect(result, isNotNull);
      expect(result!.title, 'O Alquimista');
      expect(result.author, 'Paulo Coelho');
      expect(result.totalPages, 208); // enriquecido pela BrasilAPI!
      expect(result.coverUrl, 'https://brasilapi.com.br/covers/alquimista.jpg');
    });

    test('converte corretamente entre ISBN-13 e ISBN-10', () {
      // 978-85-325-1101-0 -> 8532511015
      final isbn10 = BookApiService.convertIsbn13ToIsbn10('9788532511010');
      expect(isbn10, '8532511015');

      final isbn13 = BookApiService.convertIsbn10ToIsbn13('8532511015');
      expect(isbn13, '9788532511010');
    });

    test('mescla múltiplos itens do Google Books quando o primeiro não possui capa ou páginas', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com' &&
            request.url.path == '/books/v1/volumes') {
          final body = json.encode({
            'totalItems': 2,
            'items': [
              {
                'id': 'vol1',
                'volumeInfo': {
                  'title': 'A Bússola de Ouro',
                  'authors': ['Philip Pullman'],
                  'description': 'Sinopse oficial.',
                },
              },
              {
                'id': 'vol2',
                'volumeInfo': {
                  'title': 'A Bússola de Ouro',
                  'pageCount': 344,
                  'imageLinks': {
                    'thumbnail': 'http://books.google.com/bussola.jpg&edge=curl',
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
      expect(result!.title, 'A Bússola de Ouro');
      expect(result.author, 'Philip Pullman');
      expect(result.synopsis, 'Sinopse oficial.');
      expect(result.totalPages, 344);
      expect(result.coverUrl, 'https://books.google.com/bussola.jpg');
    });

    test('extrai páginas de texto com extractPagesFromText e campo pagination da Open Library', () async {
      expect(BookApiService.extractPagesFromText('328 p.'), 328);
      expect(BookApiService.extractPagesFromText('xii, 256 pages ; 21 cm'), 256);
      expect(BookApiService.extractPagesFromText('312 páginas'), 312);
      expect(BookApiService.extractPagesFromText('280'), 280);
      expect(BookApiService.extractPagesFromText('1 v.'), 0);
      expect(
        BookApiService.normalizeCoverUrl('http://example.com/a.jpg&edge=curl'),
        'https://example.com/a.jpg',
      );
      expect(
        BookApiService.normalizeCoverUrl('//example.com/a.jpg'),
        'https://example.com/a.jpg',
      );

      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          return http.Response(json.encode({'totalItems': 0}), 200);
        }
        if (request.url.host == 'openlibrary.org' && request.url.path == '/api/books') {
          final body = json.encode({
            'ISBN:9788532511010': {
              'title': 'Duna',
              'authors': [
                {'name': 'Frank Herbert'}
              ],
              'pagination': 'xii, 680 p. ; 23 cm',
              'cover': {
                'large': 'http://covers.openlibrary.org/b/id/42-L.jpg',
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
      expect(result!.title, 'Duna');
      expect(result.totalPages, 680);
      expect(result.coverUrl, 'https://covers.openlibrary.org/b/id/42-L.jpg');
    });

    test('recupera mediana de páginas e cover_i via Open Library Search API por ISBN', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'brasilapi.com.br' &&
            request.url.path.endsWith('9788532511010')) {
          return http.Response(
            json.encode({
              'isbn': '9788532511010',
              'title': 'O Hobbit',
              'authors': ['J.R.R. Tolkien'],
              'page_count': 0,
              'cover_url': null,
            }),
            200,
          );
        }
        if (request.url.host == 'openlibrary.org' &&
            request.url.path == '/search.json' &&
            request.url.queryParameters['isbn'] == '9788532511010') {
          return http.Response(
            json.encode({
              'numFound': 1,
              'docs': [
                {
                  'title': 'O Hobbit',
                  'author_name': ['J.R.R. Tolkien'],
                  'number_of_pages_median': 336,
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
      expect(result!.title, 'O Hobbit');
      expect(result.totalPages, 336);
      expect(result.coverUrl, 'https://covers.openlibrary.org/b/id/998877-L.jpg');
    });

    test('recupera capa e páginas via fallback de Título e Autor quando ISBN não retorna esses campos', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'brasilapi.com.br' &&
            request.url.path.endsWith('9788532511010')) {
          return http.Response(
            json.encode({
              'isbn': '9788532511010',
              'title': 'Memórias Póstumas de Brás Cubas',
              'authors': ['Machado de Assis'],
              'publisher': 'Ática',
              'synopsis': 'Clássico nacional.',
              'year': 2019,
              'page_count': 0,
              'cover_url': null,
            }),
            200,
          );
        }
        if (request.url.host == 'www.googleapis.com') {
          final q = request.url.queryParameters['q'] ?? '';
          if (q.contains('intitle:')) {
            return http.Response(
              json.encode({
                'totalItems': 1,
                'items': [
                  {
                    'volumeInfo': {
                      'title': 'Memórias Póstumas de Brás Cubas (Edição Comentada)',
                      'authors': ['Machado de Assis'],
                      'pageCount': 320,
                      'imageLinks': {
                        'large': 'https://books.google.com/memorias.jpg',
                      },
                    },
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(json.encode({'totalItems': 0}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final service = BookApiService(client: mockClient);
      final result = await service.lookupBookByIsbn('9788532511010');

      expect(result, isNotNull);
      expect(result!.title, 'Memórias Póstumas de Brás Cubas');
      expect(result.publisher, 'Ática');
      expect(result.totalPages, 320);
      expect(result.coverUrl, 'https://books.google.com/memorias.jpg');
    });
  });
}
