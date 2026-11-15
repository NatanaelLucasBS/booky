/// Modelo de configurações locais do aplicativo (meta anual e lembretes).
class AppSettingsModel {
  final int annualReadingGoal;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final DateTime updatedAt;

  const AppSettingsModel({
    this.annualReadingGoal = 12,
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 20,
    this.dailyReminderMinute = 0,
    required this.updatedAt,
  });

  factory AppSettingsModel.initial() {
    return AppSettingsModel(
      annualReadingGoal: 12,
      dailyReminderEnabled: false,
      dailyReminderHour: 20,
      dailyReminderMinute: 0,
      updatedAt: DateTime.now(),
    );
  }

  AppSettingsModel copyWith({
    int? annualReadingGoal,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    DateTime? updatedAt,
  }) {
    return AppSettingsModel(
      annualReadingGoal: annualReadingGoal ?? this.annualReadingGoal,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'annualReadingGoal': annualReadingGoal,
      'dailyReminderEnabled': dailyReminderEnabled,
      'dailyReminderHour': dailyReminderHour,
      'dailyReminderMinute': dailyReminderMinute,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();

    return AppSettingsModel(
      annualReadingGoal: (json['annualReadingGoal'] as num?)?.toInt() ?? 12,
      dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? false,
      dailyReminderHour: (json['dailyReminderHour'] as num?)?.toInt() ?? 20,
      dailyReminderMinute: (json['dailyReminderMinute'] as num?)?.toInt() ?? 0,
      updatedAt: parseDate(json['updatedAt'], now),
    );
  }
}
