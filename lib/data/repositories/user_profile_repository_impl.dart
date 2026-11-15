import 'dart:async';
import '../../domain/models/user_profile_model.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../services/storage_service.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  static const String _collection = 'user_profile';
  static const String _profileId = 'current_user';
  final StorageService _storage;
  final _controller = StreamController<UserProfileModel?>.broadcast();
  UserProfileModel? _cache;
  bool _initialized = false;

  UserProfileRepositoryImpl(this._storage);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final data = await _storage.getById(_collection, _profileId);
    if (data != null) {
      _cache = UserProfileModel.fromJson(data);
    }
    _initialized = true;
    _controller.add(_cache);
  }

  @override
  Stream<UserProfileModel?> watchProfile() async* {
    await _ensureInitialized();
    yield _cache;
    yield* _controller.stream;
  }

  @override
  Future<UserProfileModel?> getProfile() async {
    await _ensureInitialized();
    return _cache;
  }

  @override
  Future<void> saveProfile(UserProfileModel profile) async {
    await _ensureInitialized();
    await _storage.upsert(_collection, _profileId, profile.toJson());
    _cache = profile;
    _controller.add(_cache);
  }

  @override
  Future<void> updateAnnualGoal(int goal) async {
    await _ensureInitialized();
    if (_cache != null) {
      final updated = UserProfileModel(
        id: _cache!.id,
        name: _cache!.name,
        email: _cache!.email,
        annualReadingGoal: goal,
        dailyReminderEnabled: _cache!.dailyReminderEnabled,
        dailyReminderHour: _cache!.dailyReminderHour,
        dailyReminderMinute: _cache!.dailyReminderMinute,
        lastSyncAt: _cache!.lastSyncAt,
        updatedAt: DateTime.now(),
      );
      await saveProfile(updated);
    }
  }

  @override
  Future<void> updateDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await _ensureInitialized();
    if (_cache != null) {
      final updated = UserProfileModel(
        id: _cache!.id,
        name: _cache!.name,
        email: _cache!.email,
        annualReadingGoal: _cache!.annualReadingGoal,
        dailyReminderEnabled: enabled,
        dailyReminderHour: hour,
        dailyReminderMinute: minute,
        lastSyncAt: _cache!.lastSyncAt,
        updatedAt: DateTime.now(),
      );
      await saveProfile(updated);
    }
  }

  void dispose() {
    _controller.close();
  }
}
