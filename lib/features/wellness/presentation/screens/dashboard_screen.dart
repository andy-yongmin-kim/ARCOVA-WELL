import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../data/models/daily_health_data.dart';
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

  String _dateLabel() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = days[now.weekday - 1];
    return '$weekday, ${months[now.month - 1]} ${now.day}';
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
            // ── Greeting + date ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_greeting()}, ${state.profile.name}',
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 2),
                      Text(_dateLabel(),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                  icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                ),
              ],
            ),

            // ── Compact status line ───────────────────────────────────────────
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.circle, size: 7, color: AppTheme.successColor),
                const SizedBox(width: 5),
                Text('AI insights active', style: theme.textTheme.bodySmall),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Weekly summary →',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.primaryColor)),
                ),
              ],
            ),

            // ── Core metrics ─────────────────────────────────────────────────
            const SizedBox(height: 16),
            _SectionLabel(label: 'Today'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
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
                  label: 'Active',
                  goal: 'Goal 30m',
                ),
                HealthStatCard(
                  icon: Icons.favorite_outline,
                  color: AppTheme.heartColor,
                  value: '${snapshot.today.restingHeartRate} bpm',
                  label: 'Resting HR',
                  goal: 'Avg ${snapshot.restingHrSevenDayAverage} bpm',
                ),
              ],
            ),

            // ── Optional body metrics (only when at least one is present) ────
            if (snapshot.hasBodyMetrics) ...[
              const SizedBox(height: 16),
              _SectionLabel(label: 'Body'),
              const SizedBox(height: 10),
              _BodyMetricsRow(snapshot: snapshot),
            ],

            // ── Mood ─────────────────────────────────────────────────────────
            const SizedBox(height: 16),
            _MoodCard(mood: state.mood),

            // ── Streak / consistency ──────────────────────────────────────────
            const SizedBox(height: 14),
            _StreakCard(streak: streak),

            // ── Footer ───────────────────────────────────────────────────────
            const SizedBox(height: 20),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textMuted,
              letterSpacing: 0.8,
            ));
  }
}

class _BodyMetricsRow extends StatelessWidget {
  final HealthSnapshot snapshot;
  const _BodyMetricsRow({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    if (snapshot.latestWeight != null) {
      chips.add(_BodyChip(
        icon: Icons.monitor_weight_outlined,
        value: '${snapshot.latestWeight!.toStringAsFixed(1)} kg',
        label: 'Weight',
        color: AppTheme.stepsColor,
      ));
    }
    if (snapshot.latestBmi != null) {
      chips.add(_BodyChip(
        icon: Icons.straighten_outlined,
        value: snapshot.latestBmi!.toStringAsFixed(1),
        label: 'BMI',
        color: AppTheme.sleepColor,
      ));
    }
    if (snapshot.latestBodyFat != null) {
      chips.add(_BodyChip(
        icon: Icons.pie_chart_outline,
        value: '${snapshot.latestBodyFat!.toStringAsFixed(1)}%',
        label: 'Body Fat',
        color: AppTheme.activeColor,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: chips
            .expand((w) => [w, const SizedBox(width: 16)])
            .toList()
            ..removeLast(),
      ),
    );
  }
}

class _BodyChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _BodyChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.moodColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.mood, color: AppTheme.moodColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasMood ? "Today's mood logged" : 'How are you feeling?',
                    style: theme.textTheme.titleSmall),
                Text(
                  hasMood
                      ? 'Mood ${m.moodScore}/10 · Energy ${m.energyScore}/10'
                      : 'Tap to log your mood',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('$streak-day streak',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text('Consistency builds insight.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
