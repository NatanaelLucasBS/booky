import '../models/user_profile_model.dart';

abstract interface class UserProfileRepository {
  Stream<UserProfileModel?> watchProfile();
  Future<UserProfileModel?> getProfile();
  Future<void> saveProfile(UserProfileModel profile);
  Future<void> updateAnnualGoal(int goal);
  Future<void> updateDailyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  });
}
