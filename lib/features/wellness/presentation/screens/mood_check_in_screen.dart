import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/wellness_providers.dart';

class MoodCheckInScreen extends ConsumerStatefulWidget {
  const MoodCheckInScreen({super.key});

  @override
  ConsumerState<MoodCheckInScreen> createState() => _MoodCheckInScreenState();
}

class _MoodCheckInScreenState extends ConsumerState<MoodCheckInScreen> {
  double _mood = 7;
  double _energy = 6;
  double _stress = 4;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(wellnessControllerProvider.notifier).submitMood(
          _mood.round(),
          _energy.round(),
          _stress.round(),
          _noteController.text.trim(),
        );
    if (!mounted) return;
    _noteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in saved · briefing updated')),
    );
    ref.read(bottomTabProvider.notifier).state = 0;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Check-In')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _MoodSlider(
            label: 'Mood',
            value: _mood,
            color: AppTheme.moodColor,
            minLabel: 'Tired / Low',
            maxLabel: 'Peaceful / Excellent',
            onChanged: (v) => setState(() => _mood = v),
          ),
          _MoodSlider(
            label: 'Energy',
            value: _energy,
            color: AppTheme.activeColor,
            minLabel: 'Exhausted',
            maxLabel: 'Fully Charged',
            onChanged: (v) => setState(() => _energy = v),
          ),
          _MoodSlider(
            label: 'Stress',
            value: _stress,
            color: AppTheme.heartColor,
            minLabel: 'Calm & Serene',
            maxLabel: 'Highly Stressed',
            onChanged: (v) => setState(() => _stress = v),
          ),
          const SizedBox(height: 12),
          Text('What affected your mood today?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. busy day at work, good walk in the park…',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Check-In'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<double> onChanged;

  const _MoodSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.minLabel,
    required this.maxLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              Text('${value.round()}/10',
                  style: theme.textTheme.titleMedium?.copyWith(color: color)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel, style: theme.textTheme.bodySmall),
              Text(maxLabel, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
