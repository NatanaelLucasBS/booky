import '../models/app_settings_model.dart';

// Repositório de configurações do usuário
abstract interface class SettingsRepository {
  Stream<AppSettingsModel> watchSettings();
  Future<AppSettingsModel> getSettings();
  Future<void> updateAnnualGoal(int goal);
  Future<void> updateDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  });
}
