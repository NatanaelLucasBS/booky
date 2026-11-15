import '../models/app_settings_model.dart';

/// Contrato canônico do Repositório de Configurações (Meta Anual e Lembretes).
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
