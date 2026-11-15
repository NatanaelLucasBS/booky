import 'dart:async';
import '../../domain/models/app_settings_model.dart';
import '../../domain/repositories/settings_repository.dart';
import '../services/storage_service.dart';

/// Implementação da persistência de Configurações do Leitor (Meta Anual e Lembretes).
class SettingsRepositoryImpl implements SettingsRepository {
  static const String _collection = 'settings';
  static const String _settingsId = 'app_settings';
  final StorageService _storage;
  final _controller = StreamController<AppSettingsModel>.broadcast();
  AppSettingsModel? _cache;
  bool _initialized = false;

  SettingsRepositoryImpl(this._storage);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final data = await _storage.getById(_collection, _settingsId);
    if (data != null) {
      _cache = AppSettingsModel.fromJson(data);
    } else {
      _cache = AppSettingsModel(updatedAt: DateTime.now());
      await _storage.upsert(_collection, _settingsId, _cache!.toJson());
    }
    _initialized = true;
    _controller.add(_cache!);
  }

  @override
  Stream<AppSettingsModel> watchSettings() async* {
    await _ensureInitialized();
    yield _cache!;
    yield* _controller.stream;
  }

  @override
  Future<AppSettingsModel> getSettings() async {
    await _ensureInitialized();
    return _cache!;
  }

  @override
  Future<void> updateAnnualGoal(int goal) async {
    await _ensureInitialized();
    _cache = _cache!.copyWith(
      annualReadingGoal: goal,
      updatedAt: DateTime.now(),
    );
    await _storage.upsert(_collection, _settingsId, _cache!.toJson());
    _controller.add(_cache!);
  }

  @override
  Future<void> updateDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await _ensureInitialized();
    _cache = _cache!.copyWith(
      dailyReminderEnabled: enabled,
      dailyReminderHour: hour,
      dailyReminderMinute: minute,
      updatedAt: DateTime.now(),
    );
    await _storage.upsert(_collection, _settingsId, _cache!.toJson());
    _controller.add(_cache!);
  }

  void dispose() {
    _controller.close();
  }
}
