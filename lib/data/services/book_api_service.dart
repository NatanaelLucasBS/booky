import 'dart:async';
import 'dart:convert';
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

/// Serviço stateless de consulta a APIs de Livros com estratégia multiprovedor em cascata:
/// 1. Google Books API (todos os itens retornados + detalhes do volume)
/// 2. BrasilAPI (CBL / Mercosul para catálogo brasileiro)
/// 3. Open Library Books & Search API (number_of_pages, pagination, number_of_pages_median, cover_i)
/// 4. Open Library Covers API (recuperação direta de capas por ISBN)
/// 5. Fallback por Título + Autor (para recuperar capa/páginas de outras edições da mesma obra)
/// 6. Fallback de capa direta por Google volumeId
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

  /// Normaliza URLs de capas (força HTTPS e remove edge=curl do Google Books).
  static String? normalizeCoverUrl(String? rawUrl) {
    if (rawUrl == null) return null;
    var url = rawUrl.trim();
    if (url.isEmpty) return null;

    if (url.startsWith('//')) {
      url = 'https:$url';
    } else if (url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    url = url
        .replaceAll('&edge=curl', '')
        .replaceAll('?edge=curl&', '?')
        .replaceAll('?edge=curl', '');

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return null;
    return url;
  }

  /// Extrai a quantidade de páginas de campos textuais como "328 p.", "xii, 256 pages" ou "280".
  static int extractPagesFromText(String? raw) {
    if (raw == null) return 0;
    final text = raw.trim();
    if (text.isEmpty) return 0;

    final unitMatch = RegExp(
      r'(\d{1,5})\s*(?:p\.|pág\.?|pag\.?|pages?|páginas?|paginas?|p\b)',
      caseSensitive: false,
    ).firstMatch(text);
    if (unitMatch != null) {
      final parsed = int.tryParse(unitMatch.group(1) ?? '');
      if (parsed != null && parsed >= 1 && parsed <= 10000) {
        return parsed;
      }
    }

    final pureMatch = RegExp(r'^\d{1,5}$').firstMatch(text);
    if (pureMatch != null) {
      final parsed = int.tryParse(text);
      if (parsed != null && parsed >= 1 && parsed <= 10000) {
        return parsed;
      }
    }

    return 0;
  }

  /// Converte um ISBN-13 (prefixo 978) para o correspondente ISBN-10, ou retorna null se não aplicável.
  static String? convertIsbn13ToIsbn10(String isbn13) {
    final clean = normalizeIsbn(isbn13);
    if (clean.length != 13 || !clean.startsWith('978')) return null;

    final base = clean.substring(3, 12);
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(base[i]) * (10 - i);
    }
    final remainder = sum % 11;
    final check = (11 - remainder) % 11;
    final checkDigit = (check == 10) ? 'X' : check.toString();
    return '$base$checkDigit';
  }

  /// Converte um ISBN-10 para o correspondente ISBN-13 (prefixo 978), ou retorna null se inválido.
  static String? convertIsbn10ToIsbn13(String isbn10) {
    final clean = normalizeIsbn(isbn10);
    if (clean.length != 10) return null;

    final base = '978${clean.substring(0, 9)}';
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.parse(base[i]);
      sum += (i % 2 == 0) ? digit : digit * 3;
    }
    final remainder = sum % 10;
    final checkDigit = (10 - remainder) % 10;
    return '$base$checkDigit';
  }

  /// Busca metadados de livro pelo ISBN com estratégia multiprovedor e mesclagem inteligente.
  Future<BookLookupResult?> lookupBookByIsbn(String rawIsbn) async {
    final cleanIsbn = normalizeIsbn(rawIsbn);
    if (!isValidIsbn(cleanIsbn)) {
      throw const BookApiException('Código ISBN inválido. Deve conter 10 ou 13 dígitos.');
    }

    final alternateIsbn = cleanIsbn.length == 13
        ? convertIsbn13ToIsbn10(cleanIsbn)
        : convertIsbn10ToIsbn13(cleanIsbn);

    try {
      BookLookupResult? result;
      final googleVolumeIds = <String>[];

      // 1. Consulta primária: Google Books API (ISBN principal e alternativo se faltar dados)
      result = await _fetchGoogleBooks(cleanIsbn, collectedVolumeIds: googleVolumeIds);
      if (_needsEnrichment(result) && alternateIsbn != null) {
        final altGoogle = await _fetchGoogleBooks(
          alternateIsbn,
          collectedVolumeIds: googleVolumeIds,
        );
        result = _merge(result, altGoogle, originalIsbn: cleanIsbn);
      }

      // 2. BrasilAPI (CBL - forte cobertura de livros em português, ISBN principal e alternativo)
      if (_needsEnrichment(result)) {
        final brasilResult = await _fetchBrasilApi(cleanIsbn);
        result = _merge(result, brasilResult, originalIsbn: cleanIsbn);
      }
      if (_needsEnrichment(result) && alternateIsbn != null) {
        final altBrasil = await _fetchBrasilApi(alternateIsbn);
        result = _merge(result, altBrasil, originalIsbn: cleanIsbn);
      }

      // 3. Open Library Books API (ISBN principal e alternativo)
      if (_needsEnrichment(result)) {
        final openLibraryResult = await _fetchOpenLibrary(cleanIsbn);
        result = _merge(result, openLibraryResult, originalIsbn: cleanIsbn);
      }
      if (_needsEnrichment(result) && alternateIsbn != null) {
        final altOpenLibrary = await _fetchOpenLibrary(alternateIsbn);
        result = _merge(result, altOpenLibrary, originalIsbn: cleanIsbn);
      }

      // 4. Open Library Search API (number_of_pages_median e cover_i por ISBN)
      if (_needsCover(result) || _needsPages(result)) {
        final searchResult = await _fetchOpenLibrarySearchByIsbn(cleanIsbn);
        result = _merge(result, searchResult, originalIsbn: cleanIsbn);
      }
      if ((_needsCover(result) || _needsPages(result)) && alternateIsbn != null) {
        final altSearchResult = await _fetchOpenLibrarySearchByIsbn(alternateIsbn);
        result = _merge(result, altSearchResult, originalIsbn: cleanIsbn);
      }

      // 5. Open Library Covers API direta por ISBN
      if (result != null && _needsCover(result)) {
        final coverUrl = await _checkOpenLibraryCover(cleanIsbn) ??
            (alternateIsbn != null ? await _checkOpenLibraryCover(alternateIsbn) : null);
        if (coverUrl != null) {
          result = result.copyWith(coverUrl: coverUrl);
        }
      }

      // 6. Fallback por Título + Autor (recupera capa e páginas de outras edições da mesma obra)
      if (result != null &&
          result.title.trim().isNotEmpty &&
          (_needsCover(result) || _needsPages(result))) {
        final fallback = await _fetchByTitleAndAuthor(
          result.title,
          result.author,
          cleanIsbn,
        );
        result = _merge(result, fallback, originalIsbn: cleanIsbn);
      }

      // 7. Último recurso para capa: endpoint de conteúdo direto pelo volumeId do Google Books
      if (result != null && _needsCover(result) && googleVolumeIds.isNotEmpty) {
        for (final volumeId in googleVolumeIds.take(2)) {
          final coverUrl = await _checkGoogleVolumeCover(volumeId);
          if (coverUrl != null) {
            result = result?.copyWith(coverUrl: coverUrl);
            break;
          }
        }
      }

      return result;
    } on http.ClientException {
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
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw const BookApiException(
          'Sem conexão com a internet. Verifique sua rede para buscar livros pelo ISBN.',
        );
      }
      throw BookApiException('Erro ao consultar metadados do livro: $e');
    }
  }

  bool _needsCover(BookLookupResult? result) {
    return result == null || result.coverUrl == null || result.coverUrl!.trim().isEmpty;
  }

  bool _needsPages(BookLookupResult? result) {
    return result == null || result.totalPages <= 0;
  }

  /// Verifica se o resultado necessita de enriquecimento adicional por outros provedores.
  bool _needsEnrichment(BookLookupResult? result) {
    if (result == null) return true;
    return result.title.isEmpty ||
        result.author == 'Autor desconhecido' ||
        _needsPages(result) ||
        _needsCover(result) ||
        result.synopsis == null ||
        result.synopsis!.trim().isEmpty;
  }

  /// Mescla dois resultados priorizando os campos válidos e não vazios do resultado base.
  BookLookupResult? _merge(
    BookLookupResult? base,
    BookLookupResult? supplement, {
    required String originalIsbn,
  }) {
    if (base == null) {
      return supplement?.copyWith(isbn: originalIsbn);
    }
    if (supplement == null) {
      return base;
    }

    final title = base.title.isNotEmpty ? base.title : supplement.title;
    final author = (base.author.isNotEmpty && base.author != 'Autor desconhecido')
        ? base.author
        : supplement.author;
    final publisher = (base.publisher != null && base.publisher!.trim().isNotEmpty)
        ? base.publisher
        : supplement.publisher;
    final publishedYear = base.publishedYear ?? supplement.publishedYear;
    final genre = (base.genre != null && base.genre!.trim().isNotEmpty)
        ? base.genre
        : supplement.genre;
    final synopsis = (base.synopsis != null && base.synopsis!.trim().isNotEmpty)
        ? base.synopsis
        : supplement.synopsis;
    final coverUrl = (base.coverUrl != null && base.coverUrl!.trim().isNotEmpty)
        ? base.coverUrl
        : supplement.coverUrl;
    final totalPages = base.totalPages > 0 ? base.totalPages : supplement.totalPages;

    return base.copyWith(
      isbn: originalIsbn,
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

  /// Consulta primária: Google Books API (tenta isbn: e query relaxada, varrendo todos os itens)
  Future<BookLookupResult?> _fetchGoogleBooks(
    String isbn, {
    List<String>? collectedVolumeIds,
  }) async {
    try {
      // 1. Busca estrita por isbn:
      var url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn');
      var response = await _client.get(url).timeout(const Duration(seconds: 7));

      Map<String, dynamic>? data;
      if (response.statusCode == 200) {
        data = json.decode(response.body) as Map<String, dynamic>;
      }

      int totalItems = (data?['totalItems'] as num?)?.toInt() ?? 0;

      // 2. Se a busca estrita não encontrou itens, tenta busca relaxada por q=$isbn
      if (totalItems == 0 || data?['items'] == null) {
        url = Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$isbn');
        response = await _client.get(url).timeout(const Duration(seconds: 7));
        if (response.statusCode == 200) {
          data = json.decode(response.body) as Map<String, dynamic>;
          totalItems = (data['totalItems'] as num?)?.toInt() ?? 0;
        }
      }

      if (totalItems == 0 || data?['items'] == null) {
        return null;
      }

      final items = data!['items'] as List<dynamic>;
      if (items.isEmpty) return null;

      BookLookupResult? merged;
      final candidateIds = <String>[];

      for (final rawItem in items) {
        if (rawItem is! Map<String, dynamic>) continue;
        final volumeId = rawItem['id']?.toString().trim();
        if (volumeId != null && volumeId.isNotEmpty) {
          candidateIds.add(volumeId);
          if (collectedVolumeIds != null && !collectedVolumeIds.contains(volumeId)) {
            collectedVolumeIds.add(volumeId);
          }
        }
        final parsed = _parseGoogleVolumeItem(rawItem, isbn);
        merged = _merge(merged, parsed, originalIsbn: isbn);
      }

      // 3. Se ainda faltar capa ou páginas, consulta o endpoint de detalhes do volume
      if ((merged == null || _needsCover(merged) || _needsPages(merged)) &&
          candidateIds.isNotEmpty) {
        for (final volumeId in candidateIds.take(2)) {
          final detail = await _fetchGoogleVolumeDetail(volumeId, isbn);
          merged = _merge(merged, detail, originalIsbn: isbn);
          if (merged != null && !_needsCover(merged) && !_needsPages(merged)) {
            break;
          }
        }
      }

      return merged;
    } catch (_) {
      return null;
    }
  }

  BookLookupResult? _parseGoogleVolumeItem(
    Map<String, dynamic> item,
    String isbn,
  ) {
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>?;
    if (volumeInfo == null) return null;

    final title = (volumeInfo['title'] as String? ?? '').trim();
    final authorsList = volumeInfo['authors'] as List<dynamic>?;
    final authorNames = authorsList
            ?.map((e) => e.toString().trim())
            .where((name) => name.isNotEmpty)
            .toList() ??
        const [];
    final author = authorNames.isNotEmpty ? authorNames.join(', ') : 'Autor desconhecido';

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

    int totalPages = (volumeInfo['pageCount'] as num?)?.toInt() ??
        (volumeInfo['printedPageCount'] as num?)?.toInt() ??
        0;
    if (totalPages <= 0) {
      totalPages = extractPagesFromText(volumeInfo['dimensions']?.toString());
    }

    String? coverUrl;
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    if (imageLinks != null) {
      final rawCover = imageLinks['extraLarge'] as String? ??
          imageLinks['large'] as String? ??
          imageLinks['medium'] as String? ??
          imageLinks['small'] as String? ??
          imageLinks['thumbnail'] as String? ??
          imageLinks['smallThumbnail'] as String?;
      coverUrl = normalizeCoverUrl(rawCover);
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

  /// Consulta detalhes completos de um volume específico do Google Books (printedPageCount e imageLinks).
  Future<BookLookupResult?> _fetchGoogleVolumeDetail(String volumeId, String isbn) async {
    try {
      final url = Uri.parse('https://www.googleapis.com/books/v1/volumes/$volumeId');
      final response = await _client.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic> || data['volumeInfo'] is! Map<String, dynamic>) {
        return null;
      }
      return _parseGoogleVolumeItem(data, isbn);
    } catch (_) {
      return null;
    }
  }

  /// Valida se há capa direta pelo volumeId no Google Books Content.
  Future<String?> _checkGoogleVolumeCover(String volumeId) async {
    try {
      final coverUrl =
          'https://books.google.com/books/content?id=$volumeId&printsec=frontcover&img=1&zoom=1';
      final response = await _client.get(Uri.parse(coverUrl)).timeout(const Duration(seconds: 4));
      final contentType = response.headers['content-type']?.toLowerCase();
      final isImage = contentType == null || contentType.startsWith('image/');
      if (response.statusCode == 200 && isImage && response.bodyBytes.length > 1500) {
        return coverUrl;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _decodeResponseBody(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } on FormatException {
      return response.body;
    }
  }

  /// Consulta intermediária: BrasilAPI (base oficial CBL / Mercosul para ISBNs brasileiros)
  Future<BookLookupResult?> _fetchBrasilApi(String isbn) async {
    try {
      final url = Uri.parse('https://brasilapi.com.br/api/isbn/v1/$isbn');
      final response = await _client.get(url).timeout(const Duration(seconds: 7));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(_decodeResponseBody(response)) as Map<String, dynamic>;
      final title = (data['title'] as String? ?? '').trim();
      if (title.isEmpty) return null;

      String author = 'Autor desconhecido';
      final authorsList = data['authors'] as List<dynamic>?;
      if (authorsList != null && authorsList.isNotEmpty) {
        final names = authorsList
            .map((e) => e.toString().trim())
            .where((name) => name.isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          author = names.join(', ');
        }
      }

      final publisher = data['publisher'] as String?;
      final publishedYear = (data['year'] as num?)?.toInt();

      String? genre;
      final subjects = data['subjects'] as List<dynamic>?;
      if (subjects != null && subjects.isNotEmpty) {
        genre = subjects.first.toString().trim();
      }

      final synopsis = data['synopsis'] as String?;
      final rawPages = data['page_count'];
      final totalPages = rawPages is num
          ? rawPages.toInt()
          : extractPagesFromText(rawPages?.toString());

      final coverUrl = normalizeCoverUrl(data['cover_url'] as String?);

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
    } catch (_) {
      return null;
    }
  }

  /// Consulta fallback: Open Library API
  Future<BookLookupResult?> _fetchOpenLibrary(String isbn) async {
    try {
      final url = Uri.parse(
        'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&jscmd=data&format=json',
      );
      final response = await _client.get(url).timeout(const Duration(seconds: 7));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final key = 'ISBN:$isbn';
      if (!data.containsKey(key)) {
        return null;
      }

      final bookData = data[key] as Map<String, dynamic>;
      final title = (bookData['title'] as String? ?? '').trim();

      String author = 'Autor desconhecido';
      final authorsList = bookData['authors'] as List<dynamic>?;
      if (authorsList != null && authorsList.isNotEmpty) {
        final names = authorsList
            .map((a) => (a as Map<String, dynamic>)['name']?.toString().trim() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        if (names.isNotEmpty) {
          author = names.join(', ');
        }
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

      int totalPages = (bookData['number_of_pages'] as num?)?.toInt() ?? 0;
      if (totalPages <= 0) {
        totalPages = extractPagesFromText(bookData['pagination']?.toString());
      }
      if (totalPages <= 0) {
        totalPages = extractPagesFromText(bookData['physical_description']?.toString());
      }

      String? synopsis;
      final notes = bookData['notes'];
      if (notes is String && notes.trim().isNotEmpty) {
        synopsis = notes.trim();
      } else if (notes is Map<String, dynamic> && notes['value'] != null) {
        synopsis = notes['value'].toString().trim();
      }

      String? coverUrl;
      final cover = bookData['cover'] as Map<String, dynamic>?;
      if (cover != null) {
        coverUrl = normalizeCoverUrl(
          cover['large'] as String? ??
              cover['medium'] as String? ??
              cover['small'] as String?,
        );
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
    } catch (_) {
      return null;
    }
  }

  /// Consulta Open Library Search API por ISBN para recuperar number_of_pages_median e cover_i.
  Future<BookLookupResult?> _fetchOpenLibrarySearchByIsbn(String isbn) async {
    try {
      final url = Uri.https('openlibrary.org', '/search.json', {
        'isbn': isbn,
        'fields': 'title,author_name,number_of_pages_median,cover_i,first_publish_year,publisher,subject',
      });
      final response = await _client.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return null;
      final docs = data['docs'];
      if (docs is! List || docs.isEmpty) return null;

      BookLookupResult? merged;
      for (final doc in docs.take(5)) {
        if (doc is! Map<String, dynamic>) continue;
        final parsed = _parseOpenLibrarySearchDoc(doc, isbn);
        merged = _merge(merged, parsed, originalIsbn: isbn);
      }
      return merged;
    } catch (_) {
      return null;
    }
  }

  BookLookupResult _parseOpenLibrarySearchDoc(
    Map<String, dynamic> doc,
    String isbn,
  ) {
    final title = (doc['title'] as String? ?? '').trim();

    String author = 'Autor desconhecido';
    final authorsList = doc['author_name'] as List<dynamic>?;
    if (authorsList != null && authorsList.isNotEmpty) {
      final names = authorsList
          .map((e) => e.toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        author = names.join(', ');
      }
    }

    String? publisher;
    final publishers = doc['publisher'] as List<dynamic>?;
    if (publishers != null && publishers.isNotEmpty) {
      publisher = publishers.first.toString().trim();
    }

    final publishedYear = (doc['first_publish_year'] as num?)?.toInt();

    String? genre;
    final subjects = doc['subject'] as List<dynamic>?;
    if (subjects != null && subjects.isNotEmpty) {
      genre = subjects.first.toString().trim();
    }

    final totalPages = (doc['number_of_pages_median'] as num?)?.toInt() ?? 0;

    String? coverUrl;
    final coverId = (doc['cover_i'] as num?)?.toInt();
    if (coverId != null && coverId > 0) {
      coverUrl = 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
    }

    return BookLookupResult(
      isbn: isbn,
      title: title,
      author: author,
      publisher: publisher,
      publishedYear: publishedYear,
      genre: genre,
      coverUrl: coverUrl,
      totalPages: totalPages,
    );
  }

  /// Verifica se a Open Library possui capa direta para o ISBN via serviço de Covers.
  Future<String?> _checkOpenLibraryCover(String isbn) async {
    try {
      final coverUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg?default=false';
      final response = await _client.get(Uri.parse(coverUrl)).timeout(const Duration(seconds: 4));

      // Se existir, a Open Library retorna 200. Quando não existe e default=false, retorna 404
      if (response.statusCode == 200 && response.bodyBytes.length > 500) {
        return 'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fallback por Título + Autor para recuperar capa e páginas de outras edições da mesma obra.
  Future<BookLookupResult?> _fetchByTitleAndAuthor(
    String title,
    String author,
    String originalIsbn,
  ) async {
    BookLookupResult? merged = await _fetchGoogleBooksByTitleAuthor(
      title,
      author,
      originalIsbn,
    );

    if (_needsCover(merged) || _needsPages(merged)) {
      final olSearch = await _fetchOpenLibrarySearchByTitleAuthor(
        title,
        author,
        originalIsbn,
      );
      merged = _merge(merged, olSearch, originalIsbn: originalIsbn);
    }

    return merged;
  }

  Future<BookLookupResult?> _fetchGoogleBooksByTitleAuthor(
    String title,
    String author,
    String originalIsbn,
  ) async {
    try {
      final cleanTitle = title.trim();
      if (cleanTitle.isEmpty) return null;

      final firstAuthor = _extractPrimaryAuthor(author);
      final query = firstAuthor != null
          ? 'intitle:"$cleanTitle"+inauthor:"$firstAuthor"'
          : 'intitle:"$cleanTitle"';

      final url = Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': query,
        'maxResults': '5',
      });
      final response = await _client.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return null;
      final items = data['items'];
      if (items is! List || items.isEmpty) return null;

      BookLookupResult? merged;
      for (final rawItem in items.take(5)) {
        if (rawItem is! Map<String, dynamic>) continue;
        final parsed = _parseGoogleVolumeItem(rawItem, originalIsbn);
        if (parsed == null) continue;
        if (_titlesRoughlyMatch(cleanTitle, parsed.title)) {
          merged = _merge(merged, parsed, originalIsbn: originalIsbn);
        }
      }
      return merged;
    } catch (_) {
      return null;
    }
  }

  Future<BookLookupResult?> _fetchOpenLibrarySearchByTitleAuthor(
    String title,
    String author,
    String originalIsbn,
  ) async {
    try {
      final cleanTitle = title.trim();
      if (cleanTitle.isEmpty) return null;

      final firstAuthor = _extractPrimaryAuthor(author);
      final params = <String, String>{
        'title': cleanTitle,
        'limit': '5',
        'fields': 'title,author_name,number_of_pages_median,cover_i',
      };
      if (firstAuthor != null) {
        params['author'] = firstAuthor;
      }

      final url = Uri.https('openlibrary.org', '/search.json', params);
      final response = await _client.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return null;
      final docs = data['docs'];
      if (docs is! List || docs.isEmpty) return null;

      BookLookupResult? merged;
      for (final doc in docs.take(5)) {
        if (doc is! Map<String, dynamic>) continue;
        final parsed = _parseOpenLibrarySearchDoc(doc, originalIsbn);
        if (_titlesRoughlyMatch(cleanTitle, parsed.title)) {
          merged = _merge(merged, parsed, originalIsbn: originalIsbn);
        }
      }
      return merged;
    } catch (_) {
      return null;
    }
  }

  String? _extractPrimaryAuthor(String author) {
    final trimmed = author.trim();
    if (trimmed.isEmpty || trimmed == 'Autor desconhecido') return null;
    final first = trimmed.split(',').first.trim();
    return first.isEmpty ? null : first;
  }

  bool _titlesRoughlyMatch(String expected, String candidate) {
    final a = _normalizeForMatch(expected);
    final b = _normalizeForMatch(candidate);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b || b.contains(a) || a.contains(b)) return true;

    final aBase = _normalizeForMatch(expected.split(RegExp(r'[:\-(]')).first);
    final bBase = _normalizeForMatch(candidate.split(RegExp(r'[:\-(]')).first);
    if (aBase.length >= 4 &&
        bBase.length >= 4 &&
        (bBase.contains(aBase) || aBase.contains(bBase))) {
      return true;
    }

    final wordsA = a.split(' ').where((w) => w.length >= 3).toSet();
    final wordsB = b.split(' ').where((w) => w.length >= 3).toSet();
    if (wordsA.isEmpty || wordsB.isEmpty) return false;

    final matches = wordsA.where(wordsB.contains).length;
    return matches / wordsA.length >= 0.6;
  }

  String _normalizeForMatch(String input) {
    const accented = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const plain = 'aaaaaeeeeiiiiooooouuuucn';
    var lower = input.toLowerCase();
    for (int i = 0; i < accented.length; i++) {
      lower = lower.replaceAll(accented[i], plain[i]);
    }
    return lower
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

