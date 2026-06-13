import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MedicalDisclaimerScreen extends StatelessWidget {
  const MedicalDisclaimerScreen({super.key});

  static const _points = <String>[
    'Arcova Well is a wellness and lifestyle tool. It is not a medical device and does not diagnose, treat, cure, or prevent any disease.',
    'Insights and recommendations are generated from trends in your data and general wellness guidance. They are not a substitute for professional medical advice.',
    'Always consult a qualified healthcare provider with any questions about a medical condition or before making changes to your health routine. In an emergency, contact your local emergency services.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Disclaimer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          for (final p in _points)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.tertiaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(p,
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
