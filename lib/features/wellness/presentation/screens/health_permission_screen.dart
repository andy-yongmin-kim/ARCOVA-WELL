import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/wellness_providers.dart';

class _DataType {
  final IconData icon;
  final String title;
  final String subtitle;
  const _DataType(this.icon, this.title, this.subtitle);
}

const _androidDataTypes = <_DataType>[
  _DataType(Icons.bedtime_outlined, 'Sleep Duration', 'Circadian & recovery cycles'),
  _DataType(Icons.directions_walk_outlined, 'Steps Count', 'Physical activity baseline'),
  _DataType(Icons.local_fire_department_outlined, 'Active Minutes', 'Elevated heart-rate activity'),
  _DataType(Icons.favorite_outline, 'Resting Heart Rate', 'Autonomic & heart health'),
];

/// Final onboarding step: connect Health Connect (Android) or explain mood+AI focus (iOS).
class HealthPermissionScreen extends ConsumerStatefulWidget {
  const HealthPermissionScreen({super.key});

  @override
  ConsumerState<HealthPermissionScreen> createState() => _HealthPermissionScreenState();
}

class _HealthPermissionScreenState extends ConsumerState<HealthPermissionScreen> {
  bool _busy = false;

  Future<void> _proceed({required bool useSample}) async {
    setState(() => _busy = true);
    final controller = ref.read(wellnessControllerProvider.notifier);
    final granted = await controller.connectHealth(sampleFallback: useSample);
    await controller.generateBriefing();

    ref.read(onboardingProvider.notifier)
        .setHealthConnected(!useSample && granted);
    ref.read(onboardingProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid ? _buildAndroid(context) : _buildIOS(context);
  }

  Widget _buildAndroid(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Connect your health data', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Arcova reads the following to build your daily insights. Your data stays on your device unless you enable cloud backup.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _androidDataTypes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = _androidDataTypes[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(d.icon, color: AppTheme.primaryColor),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.title, style: theme.textTheme.titleMedium),
                                Text(d.subtitle, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_busy)
                const Center(child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ))
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _proceed(useSample: false),
                    child: const Text('Connect Health Data'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _proceed(useSample: true),
                  child: const Text('Use Sample Data'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOS(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('You\'re all set', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Arcova will track your daily mood check-ins and generate personalized AI briefings. '
                'Device health metrics (sleep, steps, heart rate) are available on Android via Health Connect.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              for (final item in const [
                (Icons.mood, 'Daily Mood Check-In', 'Log how you feel each day'),
                (Icons.article_outlined, 'AI Daily Briefing', 'Personalized insight every morning'),
                (Icons.cloud_outlined, 'Cloud Backup', 'Optional — sign in + premium required'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(item.$1, color: AppTheme.primaryColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$2, style: theme.textTheme.titleMedium),
                              Text(item.$3, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _proceed(useSample: true),
                    child: const Text('Get Started'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
