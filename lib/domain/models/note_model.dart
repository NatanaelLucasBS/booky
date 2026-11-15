import 'enums.dart';

/// Modelo de domínio para anotações, citações (com OCR) e resenhas do livro.
class NoteModel {
  final String id;
  final String bookId;
  final NoteType type;
  final String? chapter;
  final int? page;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.bookId,
    required this.type,
    this.chapter,
    this.page,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteModel copyWith({
    String? id,
    String? bookId,
    NoteType? type,
    String? chapter,
    int? page,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      type: type ?? this.type,
      chapter: chapter ?? this.chapter,
      page: page ?? this.page,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'type': type.name,
      'chapter': chapter,
      'page': page,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();

    return NoteModel(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      type: NoteType.fromString(json['type'] as String?),
      chapter: json['chapter'] as String?,
      page: (json['page'] as num?)?.toInt(),
      content: json['content'] as String? ?? '',
      createdAt: parseDate(json['createdAt'], now),
      updatedAt: parseDate(json['updatedAt'], now),
    );
  }
}
