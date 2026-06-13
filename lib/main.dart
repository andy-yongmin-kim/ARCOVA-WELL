import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/wellness/data/models/user_profile.dart';
import 'features/wellness/data/models/daily_health_data.dart';
import 'features/wellness/data/models/mood_check_in.dart';
import 'features/wellness/data/models/daily_briefing.dart';
import 'features/wellness/data/repositories/wellness_repository.dart';
import 'features/wellness/providers/wellness_providers.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — guard against misconfigured google-services.json
  bool firebaseAvailable = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseAvailable = true;
  } catch (e) {
    debugPrint('Firebase init failed (offline mode): $e');
  }

  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(DailyHealthDataAdapter());
  Hive.registerAdapter(MoodCheckInAdapter());
  Hive.registerAdapter(DailyBriefingAdapter());

  // Shared 'settings' box holds onboarding flags + premium status.
  await Hive.openBox('settings');

  final repository = WellnessRepository();
  await repository.init();

  runApp(
    ProviderScope(
      overrides: [
        wellnessRepositoryProvider.overrideWithValue(repository),
        firebaseAvailableProvider.overrideWithValue(firebaseAvailable),
      ],
      child: const ArcovaWellApp(),
    ),
  );
}
