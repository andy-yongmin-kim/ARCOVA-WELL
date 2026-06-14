import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../data/models/mood_check_in.dart';
import '../../providers/wellness_providers.dart';
import '../format.dart';
import '../widgets/health_stat_card.dart';
import 'weekly_summary_screen.dart';
import 'medical_disclaimer_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(wellnessControllerProvider);
    final streak = ref.watch(checkInStreakProvider);
    final snapshot = state.snapshot;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_greeting()}, ${state.profile.name}',
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppTheme.successColor),
                          const SizedBox(width: 6),
                          Text('AI insights active', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                  icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                HealthStatCard(
                  icon: Icons.bedtime_outlined,
                  color: AppTheme.sleepColor,
                  value: Fmt.duration(snapshot.today.sleepDurationMinutes),
                  label: 'Sleep',
                  goal: 'Goal 7h 30m',
                ),
                HealthStatCard(
                  icon: Icons.directions_walk_outlined,
                  color: AppTheme.stepsColor,
                  value: Fmt.number(snapshot.today.steps),
                  label: 'Steps',
                  goal: 'Goal 8,000',
                ),
                HealthStatCard(
                  icon: Icons.local_fire_department_outlined,
                  color: AppTheme.activeColor,
                  value: '${snapshot.today.activeMinutes}m',
                  label: 'Active Minutes',
                  goal: 'Goal 30m',
                ),
                HealthStatCard(
                  icon: Icons.favorite_outline,
                  color: AppTheme.heartColor,
                  value: '${snapshot.today.restingHeartRate} bpm',
                  label: 'Resting HR',
                  goal: '7-day avg ${snapshot.restingHrSevenDayAverage}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MoodCard(mood: state.mood),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(bottomTabProvider.notifier).state = 1,
                icon: const Icon(Icons.article_outlined),
                label: const Text('View Daily Briefing'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(bottomTabProvider.notifier).state = 2,
                    child: const Text('Check In Mood'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()),
                    ),
                    child: const Text('Weekly Summary'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _StreakCard(streak: streak),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MedicalDisclaimerScreen()),
                ),
                child: Text('Medical disclaimer',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        decoration: TextDecoration.underline)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCard extends ConsumerWidget {
  final MoodCheckIn? mood;
  const _MoodCard({required this.mood});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final m = mood;
    final hasMood = m != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.moodColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.mood, color: AppTheme.moodColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasMood ? "Today's mood logged" : 'How are you feeling?',
                    style: theme.textTheme.titleMedium),
                Text(
                  hasMood
                      ? 'Mood ${m.moodScore}/10 · Energy ${m.energyScore}/10'
                      : 'Tap Check-In to log your mood',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!hasMood)
            TextButton(
              onPressed: () => ref.read(bottomTabProvider.notifier).state = 2,
              child: const Text('Check in'),
            ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (streak.clamp(0, 7)) / 7.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white),
              const SizedBox(width: 10),
              Text('$streak-day check-in streak',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text('Keep going — consistency builds insight.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
