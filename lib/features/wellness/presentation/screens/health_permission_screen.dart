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

const _iosDataTypes = <_DataType>[
  _DataType(Icons.bedtime_outlined, 'Sleep', 'Duration from Apple Health'),
  _DataType(Icons.directions_walk_outlined, 'Steps', 'Daily step count'),
  _DataType(Icons.local_fire_department_outlined, 'Active Minutes', 'Exercise time'),
  _DataType(Icons.favorite_outline, 'Resting Heart Rate', 'Resting BPM'),
  _DataType(Icons.monitor_weight_outlined, 'Weight & Body Metrics', 'Optional — when available in Apple Health'),
];

/// Final onboarding step: connect Apple Health (iOS) or Health Connect (Android).
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
                'Arcova reads the following from Health Connect to build your daily insights. Your data stays on your device unless you enable cloud backup.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _androidDataTypes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = _androidDataTypes[i];
                    return _DataTypeRow(d: d);
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
              Text('Connect Apple Health', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Arcova reads the following from Apple Health to build your daily insights. Your data stays on your device unless you enable cloud backup.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _iosDataTypes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = _iosDataTypes[i];
                    return _DataTypeRow(d: d);
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
                    child: const Text('Connect Apple Health'),
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
}

class _DataTypeRow extends StatelessWidget {
  final _DataType d;
  const _DataTypeRow({required this.d});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
  }
}
