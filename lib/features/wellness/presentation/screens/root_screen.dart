import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/wellness_providers.dart';
import 'welcome_screen.dart';
import 'main_shell.dart';

/// Entry point. Shows a brief splash, then routes to the onboarding flow or
/// the main app depending on persisted onboarding state.
class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const _SplashView();

    final onboarded = ref.watch(onboardingProvider).hasOnboarded;
    return onboarded ? const MainShell() : const _OnboardingFlow();
  }
}

/// Hosts the linear onboarding stack in its own Navigator so that completing
/// onboarding (which flips the provider) cleanly tears the whole flow down.
class _OnboardingFlow extends StatelessWidget {
  const _OnboardingFlow();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.accentGradient,
              ),
              child: const Icon(Icons.all_inclusive, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Arcova Well',
              style: TextStyle(
                inherit: false,
                fontFamily: 'Pretendard',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal AI wellness companion',
              style: TextStyle(
                inherit: false,
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: AppTheme.darkTextPrimary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
