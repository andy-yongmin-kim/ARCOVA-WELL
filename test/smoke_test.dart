// Runtime smoke test: builds the real provider graph + Dashboard first frame
// over a temporary Hive store. Does NOT call main(), so Firebase is never
// initialized (Dashboard itself touches no Firebase APIs).

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arcova_well/features/wellness/data/models/user_profile.dart';
import 'package:arcova_well/features/wellness/data/models/daily_health_data.dart';
import 'package:arcova_well/features/wellness/data/models/mood_check_in.dart';
import 'package:arcova_well/features/wellness/data/models/daily_briefing.dart';
import 'package:arcova_well/features/wellness/data/repositories/wellness_repository.dart';
import 'package:arcova_well/features/wellness/providers/wellness_providers.dart';
import 'package:arcova_well/features/wellness/presentation/screens/dashboard_screen.dart';

void main() {
  late Directory tempDir;
  late WellnessRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('arcova_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DailyHealthDataAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(MoodCheckInAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyBriefingAdapter());
    await Hive.openBox('settings');
    repo = WellnessRepository();
    await repo.init();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('Dashboard builds its first frame from the provider graph',
      timeout: const Timeout(Duration(seconds: 30)), (tester) async {
    // Hive file writes are real async I/O — use runAsync to escape fake-async.
    await tester.runAsync(() async {
      await repo.saveHealthData(DailyHealthData(
        date: WellnessRepository.dateKey(),
        sleepDurationMinutes: 378,
        steps: 4321,
        activeMinutes: 28,
        restingHeartRate: 71,
      ));
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [wellnessRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    // Two bounded pumps drive the first render and any Material animations.
    // Avoid pumpAndSettle — LinearProgressIndicator creates an indefinite animation.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Core metric labels rendered = controller built, snapshot computed,
    // metrics-first layout renders without overflow or assertions.
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
    // Seeded value formatted via Fmt.duration.
    expect(find.text('6h 18m'), findsOneWidget);
    // Briefing CTA no longer lives on Home — it is in the Briefing tab.
    expect(find.text('View Daily Briefing'), findsNothing);
    // Weekly summary is accessible via inline link, not a bottom CTA.
    expect(find.text('Weekly summary →'), findsOneWidget);
  });
}
