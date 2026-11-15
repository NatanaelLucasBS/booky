/// Modelo de domínio de uma Sessão de Leitura com cronômetro e páginas lidas.
class ReadingSessionModel {
  final String id;
  final String bookId;
  final DateTime startTime;
  final int durationSeconds;
  final int startPage;
  final int endPage;
  final int pagesRead;
  final String dateKey;
  final DateTime updatedAt;

  const ReadingSessionModel({
    required this.id,
    required this.bookId,
    required this.startTime,
    required this.durationSeconds,
    required this.startPage,
    required this.endPage,
    required this.pagesRead,
    required this.dateKey,
    required this.updatedAt,
  });

  ReadingSessionModel copyWith({
    String? id,
    String? bookId,
    DateTime? startTime,
    int? durationSeconds,
    int? startPage,
    int? endPage,
    int? pagesRead,
    String? dateKey,
    DateTime? updatedAt,
  }) {
    return ReadingSessionModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      pagesRead: pagesRead ?? this.pagesRead,
      dateKey: dateKey ?? this.dateKey,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'startTime': startTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'startPage': startPage,
      'endPage': endPage,
      'pagesRead': pagesRead,
      'dateKey': dateKey,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReadingSessionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    final start = parseDate(json['startTime'], now);
    final fallbackDateKey =
        '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';

    return ReadingSessionModel(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      startTime: start,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      startPage: (json['startPage'] as num?)?.toInt() ?? 0,
      endPage: (json['endPage'] as num?)?.toInt() ?? 0,
      pagesRead: (json['pagesRead'] as num?)?.toInt() ?? 0,
      dateKey: json['dateKey'] as String? ?? fallbackDateKey,
      updatedAt: parseDate(json['updatedAt'], now),
    );
  }
}
