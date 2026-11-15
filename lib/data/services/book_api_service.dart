import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Dados consolidados de busca de livro por ISBN.
class BookLookupResult {
  final String isbn;
  final String title;
  final String author;
  final String? publisher;
  final int? publishedYear;
  final String? genre;
  final String? synopsis;
  final String? coverUrl;
  final int totalPages;

  const BookLookupResult({
    required this.isbn,
    required this.title,
    required this.author,
    this.publisher,
    this.publishedYear,
    this.genre,
    this.synopsis,
    this.coverUrl,
    this.totalPages = 0,
  });

  BookLookupResult copyWith({
    String? isbn,
    String? title,
    String? author,
    String? publisher,
    int? publishedYear,
    String? genre,
    String? synopsis,
    String? coverUrl,
    int? totalPages,
  }) {
    return BookLookupResult(
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      publishedYear: publishedYear ?? this.publishedYear,
      genre: genre ?? this.genre,
      synopsis: synopsis ?? this.synopsis,
      coverUrl: coverUrl ?? this.coverUrl,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

/// Exceção personalizada para falhas nas APIs de livros.
class BookApiException implements Exception {
  final String message;
  const BookApiException(this.message);

  @override
  String toString() => message;
}

/// Serviço stateless de consulta a APIs de Livros (Google Books + Open Library).
/// Slide 25 da Aula 24 (Arquitetura Flutter).
class BookApiService {
  final http.Client _client;

  BookApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Normaliza string de ISBN removendo hífens e espaços.
  static String normalizeIsbn(String raw) {
    return raw.replaceAll(RegExp(r'[\s\-]'), '').trim().toUpperCase();
  }

  /// Valida se uma string é um ISBN de 10 ou 13 dígitos.
  static bool isValidIsbn(String raw) {
    final clean = normalizeIsbn(raw);
    if (clean.length == 10) {
      return RegExp(r'^\d{9}[\dX]$').hasMatch(clean);
    }
    if (clean.length == 13) {
      return RegExp(r'^\d{13}$').hasMatch(clean);
    }
    return false;
  }

  /// Busca metadados de livro pelo ISBN, consultando primeiro o Google Books
  /// com fallback automático para Open Library.
  Future<BookLookupResult?> lookupBookByIsbn(String rawIsbn) async {
    final cleanIsbn = normalizeIsbn(rawIsbn);
    if (!isValidIsbn(cleanIsbn)) {
      throw const BookApiException('Código ISBN inválido. Deve conter 10 ou 13 dígitos.');
    }

    try {
      // 1. Tentar Google Books API
      BookLookupResult? result = await _fetchGoogleBooks(cleanIsbn);

      // Se não encontrou ou faltam dados essenciais (título, autor, capa ou páginas)
      if (result == null ||
          result.title.isEmpty ||
          result.author.isEmpty ||
          result.totalPages == 0 ||
          result.coverUrl == null) {
        // 2. Fallback para Open Library API
        final openLibraryResult = await _fetchOpenLibrary(cleanIsbn);
        if (openLibraryResult != null) {
          if (result == null) {
            result = openLibraryResult;
          } else {
            // Mescla os dados preenchendo lacunas
            result = result.copyWith(
              title: result.title.isNotEmpty ? result.title : openLibraryResult.title,
              author: result.author.isNotEmpty ? result.author : openLibraryResult.author,
              publisher: result.publisher ?? openLibraryResult.publisher,
              publishedYear: result.publishedYear ?? openLibraryResult.publishedYear,
              genre: result.genre ?? openLibraryResult.genre,
              synopsis: result.synopsis ?? openLibraryResult.synopsis,
              coverUrl: result.coverUrl ?? openLibraryResult.coverUrl,
              totalPages: result.totalPages > 0 ? result.totalPages : openLibraryResult.totalPages,
            );
          }
        }
      }

      return result;
    } on SocketException {
      throw const BookApiException(
        'Sem conexão com a internet. Verifique sua rede para buscar livros pelo ISBN.',
      );
    } on TimeoutException {
      throw const BookApiException(
        'Tempo limite excedido ao consultar serviços de livros. Tente novamente.',
      );
    } on BookApiException {
      rethrow;
    } catch (e) {
      throw BookApiException('Erro ao consultar metadados do livro: $e');
    }
  }

  /// Consulta primária: Google Books API
  Future<BookLookupResult?> _fetchGoogleBooks(String isbn) async {
    final url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn');
    final response = await _client.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return null;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final totalItems = (data['totalItems'] as num?)?.toInt() ?? 0;
    if (totalItems == 0 || data['items'] == null) {
      return null;
    }

    final items = data['items'] as List<dynamic>;
    if (items.isEmpty) return null;

    final volumeInfo = items.first['volumeInfo'] as Map<String, dynamic>?;
    if (volumeInfo == null) return null;

    final title = volumeInfo['title'] as String? ?? '';
    final authorsList = volumeInfo['authors'] as List<dynamic>?;
    final author = authorsList != null && authorsList.isNotEmpty
        ? authorsList.map((e) => e.toString()).join(', ')
        : 'Autor desconhecido';

    final publisher = volumeInfo['publisher'] as String?;

    int? publishedYear;
    final publishedDate = volumeInfo['publishedDate'] as String?;
    if (publishedDate != null && publishedDate.length >= 4) {
      publishedYear = int.tryParse(publishedDate.substring(0, 4));
    }

    String? genre;
    final categories = volumeInfo['categories'] as List<dynamic>?;
    if (categories != null && categories.isNotEmpty) {
      genre = categories.first.toString();
    }

    final synopsis = volumeInfo['description'] as String?;
    final totalPages = (volumeInfo['pageCount'] as num?)?.toInt() ?? 0;

    String? coverUrl;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    if (imageLinks != null) {
      final rawCover = imageLinks['thumbnail'] as String? ?? imageLinks['smallThumbnail'] as String?;
      if (rawCover != null) {
        // Converte http:// para https://
        coverUrl = rawCover.startsWith('http://')
            ? rawCover.replaceFirst('http://', 'https://')
            : rawCover;
      }
    }

    return BookLookupResult(
      isbn: isbn,
      title: title,
      author: author,
      publisher: publisher,
      publishedYear: publishedYear,
      genre: genre,
      synopsis: synopsis,
      coverUrl: coverUrl,
      totalPages: totalPages,
    );
  }

  /// Consulta fallback: Open Library API
  Future<BookLookupResult?> _fetchOpenLibrary(String isbn) async {
    final url = Uri.parse(
      'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&jscmd=data&format=json',
    );
    final response = await _client.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return null;
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final key = 'ISBN:$isbn';
    if (!data.containsKey(key)) {
      return null;
    }

    final bookData = data[key] as Map<String, dynamic>;
    final title = bookData['title'] as String? ?? '';

    String author = 'Autor desconhecido';
    final authorsList = bookData['authors'] as List<dynamic>?;
    if (authorsList != null && authorsList.isNotEmpty) {
      author = authorsList
          .map((a) => (a as Map<String, dynamic>)['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .join(', ');
    }

    String? publisher;
    final publishersList = bookData['publishers'] as List<dynamic>?;
    if (publishersList != null && publishersList.isNotEmpty) {
      publisher = (publishersList.first as Map<String, dynamic>)['name']?.toString();
    }

    int? publishedYear;
    final publishDate = bookData['publish_date'] as String?;
    if (publishDate != null) {
      final match = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(publishDate);
      if (match != null) {
        publishedYear = int.tryParse(match.group(1)!);
      }
    }

    String? genre;
    final subjects = bookData['subjects'] as List<dynamic>?;
    if (subjects != null && subjects.isNotEmpty) {
      genre = (subjects.first as Map<String, dynamic>)['name']?.toString();
    }

    final totalPages = (bookData['number_of_pages'] as num?)?.toInt() ?? 0;

    String? coverUrl;
    final cover = bookData['cover'] as Map<String, dynamic>?;
    if (cover != null) {
      coverUrl = cover['large'] as String? ??
          cover['medium'] as String? ??
          cover['small'] as String?;
      if (coverUrl != null && coverUrl.startsWith('http://')) {
        coverUrl = coverUrl.replaceFirst('http://', 'https://');
      }
    }

    return BookLookupResult(
      isbn: isbn,
      title: title,
      author: author,
      publisher: publisher,
      publishedYear: publishedYear,
      genre: genre,
      synopsis: null,
      coverUrl: coverUrl,
      totalPages: totalPages,
    );
  }
}
