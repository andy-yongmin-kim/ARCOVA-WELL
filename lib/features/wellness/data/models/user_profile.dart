import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// User profile — synced from Firebase Auth, editable in Settings.
@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String email;

  @HiveField(3)
  String timezone;

  @HiveField(4)
  bool premiumStatus;

  UserProfile({
    required this.id,
    this.name = 'Guest',
    this.email = '',
    this.timezone = 'UTC',
    this.premiumStatus = false,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? timezone,
    bool? premiumStatus,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      timezone: timezone ?? this.timezone,
      premiumStatus: premiumStatus ?? this.premiumStatus,
    );
  }
}
