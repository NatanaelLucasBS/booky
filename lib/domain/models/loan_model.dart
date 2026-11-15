/// Modelo de domínio para empréstimo de livro para amigos com cálculo de atraso.
class LoanModel {
  final String id;
  final String bookId;
  final String borrowerName;
  final String borrowerContact;
  final DateTime loanDate;
  final DateTime expectedReturnDate;
  final DateTime? returnedDate;
  final bool isReturned;
  final int? notificationId;
  final DateTime updatedAt;

  const LoanModel({
    required this.id,
    required this.bookId,
    required this.borrowerName,
    required this.borrowerContact,
    required this.loanDate,
    required this.expectedReturnDate,
    this.returnedDate,
    this.isReturned = false,
    this.notificationId,
    required this.updatedAt,
  });

  bool get isOverdue =>
      !isReturned &&
      DateTime.now().isAfter(
        DateTime(
          expectedReturnDate.year,
          expectedReturnDate.month,
          expectedReturnDate.day,
          23,
          59,
          59,
        ),
      );

  LoanModel copyWith({
    String? id,
    String? bookId,
    String? borrowerName,
    String? borrowerContact,
    DateTime? loanDate,
    DateTime? expectedReturnDate,
    DateTime? returnedDate,
    bool? isReturned,
    int? notificationId,
    DateTime? updatedAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerContact: borrowerContact ?? this.borrowerContact,
      loanDate: loanDate ?? this.loanDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      returnedDate: returnedDate ?? this.returnedDate,
      isReturned: isReturned ?? this.isReturned,
      notificationId: notificationId ?? this.notificationId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'borrowerName': borrowerName,
      'borrowerContact': borrowerContact,
      'loanDate': loanDate.toIso8601String(),
      'expectedReturnDate': expectedReturnDate.toIso8601String(),
      'returnedDate': returnedDate?.toIso8601String(),
      'isReturned': isReturned,
      'notificationId': notificationId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LoanModel.fromJson(Map<String, dynamic> json) {
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

    return LoanModel(
      id: json['id'] as String? ?? '',
      bookId: json['bookId'] as String? ?? '',
      borrowerName: json['borrowerName'] as String? ?? '',
      borrowerContact: json['borrowerContact'] as String? ?? '',
      loanDate: parseDate(json['loanDate'], now),
      expectedReturnDate: parseDate(json['expectedReturnDate'], now),
      returnedDate: parseNullableDate(json['returnedDate']),
      isReturned: json['isReturned'] as bool? ?? false,
      notificationId: (json['notificationId'] as num?)?.toInt(),
      updatedAt: parseDate(json['updatedAt'], now),
    );
  }
}
