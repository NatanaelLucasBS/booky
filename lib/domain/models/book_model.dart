import 'enums.dart';

/// Modelo de domínio do Livro no acervo pessoal.
class BookModel {
  final String id;
  final String? isbn;
  final String title;
  final String author;
  final String? publisher;
  final int? publishedYear;
  final String? genre;
  final String? synopsis;
  final String? coverUrl;
  final int totalPages;
  final int currentPage;
  final BookStatus status;
  final BookFormat format;
  final double? rating;
  final List<String> tags;
  final List<String> shelfIds;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookModel({
    required this.id,
    this.isbn,
    required this.title,
    required this.author,
    this.publisher,
    this.publishedYear,
    this.genre,
    this.synopsis,
    this.coverUrl,
    this.totalPages = 0,
    this.currentPage = 0,
    this.status = BookStatus.wantToRead,
    this.format = BookFormat.physical,
    this.rating,
    this.tags = const [],
    this.shelfIds = const [],
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progressPercent =>
      totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;

  bool get isFinished =>
      status == BookStatus.read ||
      (totalPages > 0 && currentPage >= totalPages);

  BookModel copyWith({
    String? id,
    String? isbn,
    String? title,
    String? author,
    String? publisher,
    int? publishedYear,
    String? genre,
    String? synopsis,
    String? coverUrl,
    int? totalPages,
    int? currentPage,
    BookStatus? status,
    BookFormat? format,
    double? rating,
    List<String>? tags,
    List<String>? shelfIds,
    DateTime? startedAt,
    DateTime? finishedAt,
    bool clearStartedAt = false,
    bool clearFinishedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      publishedYear: publishedYear ?? this.publishedYear,
      genre: genre ?? this.genre,
      synopsis: synopsis ?? this.synopsis,
      coverUrl: coverUrl ?? this.coverUrl,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      format: format ?? this.format,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      shelfIds: shelfIds ?? this.shelfIds,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'author': author,
      'publisher': publisher,
      'publishedYear': publishedYear,
      'genre': genre,
      'synopsis': synopsis,
      'coverUrl': coverUrl,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'status': status.name,
      'format': format.name,
      'rating': rating,
      'tags': tags,
      'shelfIds': shelfIds,
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BookModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final now = DateTime.now();

    return BookModel(
      id: json['id'] as String? ?? '',
      isbn: json['isbn'] as String?,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publisher: json['publisher'] as String?,
      publishedYear: json['publishedYear'] as int?,
      genre: json['genre'] as String?,
      synopsis: json['synopsis'] as String?,
      coverUrl: json['coverUrl'] as String?,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      status: BookStatus.fromString(json['status'] as String?),
      format: BookFormat.fromString(json['format'] as String?),
      rating: (json['rating'] as num?)?.toDouble(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
      shelfIds:
          (json['shelfIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              const [],
      startedAt: parseNullableDate(json['startedAt']),
      finishedAt: parseNullableDate(json['finishedAt']),
      createdAt: parseDate(json['createdAt'], now),
      updatedAt: parseDate(json['updatedAt'], now),
    );
  }
}
