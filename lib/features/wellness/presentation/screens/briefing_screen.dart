import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/daily_briefing.dart';
import '../../providers/wellness_providers.dart';
import '../format.dart';

class BriefingScreen extends ConsumerWidget {
  const BriefingScreen({super.key});

  void _celebrate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.celebration, color: AppTheme.tertiaryColor, size: 40),
        title: const Text('Nicely done'),
        content: const Text(
            "You've completed today's actions. Small, consistent steps add up."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(wellnessControllerProvider);
    final briefing = state.briefing;
    final snapshot = state.snapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DAILY BRIEFING'),
        actions: [
          IconButton(
            tooltip: 'Regenerate',
            onPressed: state.isGeneratingBriefing
                ? null
                : () => ref.read(wellnessControllerProvider.notifier).generateBriefing(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.isGeneratingBriefing
          ? const Center(child: CircularProgressIndicator())
          : briefing == null
              ? _EmptyBriefing(
                  onGenerate: () =>
                      ref.read(wellnessControllerProvider.notifier).generateBriefing())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _SummaryCard(briefing: briefing),
                    const SizedBox(height: 20),
                    Text('Yesterday snapshot', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MiniStat(
                            label: 'Sleep',
                            value: Fmt.duration(snapshot.today.sleepDurationMinutes)),
                        _MiniStat(label: 'Steps', value: Fmt.number(snapshot.today.steps)),
                        _MiniStat(
                            label: 'Rest HR',
                            value: '${snapshot.today.restingHeartRate}'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Key observations', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ...briefing.insights.map((i) => _BulletTile(
                          icon: Icons.lightbulb_outline,
                          color: AppTheme.sleepColor,
                          text: i,
                        )),
                    const SizedBox(height: 24),
                    Text('Personalized actions', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ...briefing.recommendations.asMap().entries.map((e) => _BulletTile(
                          icon: Icons.check_circle_outline,
                          color: AppTheme.accentColor,
                          text: e.value,
                          leadingNumber: e.key + 1,
                        )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _celebrate(context),
                        child: const Text('Mark as Done'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Source: ${briefing.source == 'gemini' ? 'AI (Gemini)' : 'On-device'}',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _EmptyBriefing extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyBriefing({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text('No briefing yet for today',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onGenerate, child: const Text('Generate Briefing')),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DailyBriefing briefing;
  const _SummaryCard({required this.briefing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Summary',
                  style: TextStyle(
                      inherit: false,
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          Text(briefing.summary,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white, height: 1.5)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BulletTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final int? leadingNumber;
  const _BulletTile({
    required this.icon,
    required this.color,
    required this.text,
    this.leadingNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leadingNumber != null)
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text('$leadingNumber',
                  style: const TextStyle(
                      inherit: false,
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            )
          else
            Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
          ),
        ],
      ),
    );
  }
}
