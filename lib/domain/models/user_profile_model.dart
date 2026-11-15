/// Modelo de domínio simplificado mantido para compatibilidade.
class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final int annualReadingGoal;
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final DateTime? lastSyncAt;
  final DateTime updatedAt;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.annualReadingGoal = 12,
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 20,
    this.dailyReminderMinute = 0,
    this.lastSyncAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'annualReadingGoal': annualReadingGoal,
        'dailyReminderEnabled': dailyReminderEnabled,
        'dailyReminderHour': dailyReminderHour,
        'dailyReminderMinute': dailyReminderMinute,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      annualReadingGoal: (json['annualReadingGoal'] as num?)?.toInt() ?? 12,
      dailyReminderEnabled: json['dailyReminderEnabled'] as bool? ?? false,
      dailyReminderHour: (json['dailyReminderHour'] as num?)?.toInt() ?? 20,
      dailyReminderMinute: (json['dailyReminderMinute'] as num?)?.toInt() ?? 0,
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.tryParse(json['lastSyncAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
