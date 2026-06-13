import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/wellness_providers.dart';
import '../format.dart';

class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = ref.watch(weeklySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('This Week')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _SummaryTile(
                  label: 'Average Sleep',
                  value: s.averageSleepMinutes == 0 ? '—' : Fmt.duration(s.averageSleepMinutes),
                  color: AppTheme.sleepColor),
              _SummaryTile(
                  label: 'Average Steps',
                  value: s.averageSteps == 0 ? '—' : Fmt.number(s.averageSteps),
                  color: AppTheme.stepsColor),
              _SummaryTile(
                  label: 'Average Mood',
                  value: s.averageMood == 0 ? '—' : '${s.averageMood.toStringAsFixed(1)}/10',
                  color: AppTheme.moodColor),
              _SummaryTile(label: 'Best Day', value: s.bestDayLabel, color: AppTheme.tertiaryColor),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights, color: AppTheme.primaryColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Your mood was generally higher after nights with longer sleep. Protecting your sleep window is the highest-leverage habit this week.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next week focus', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('Improve sleep consistency — aim for the same bedtime (±30 min) on 5+ nights.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                Text('${s.daysLogged} of 7 days logged this week',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
