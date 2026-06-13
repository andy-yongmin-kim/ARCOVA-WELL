import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'sign_in_screen.dart';

/// First screen of the onboarding flow.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.accentGradient,
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(Icons.spa_outlined, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 40),
              Text(
                'Welcome to Arcova Well',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Understand your body, calm your mind, and turn daily insight into action.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
