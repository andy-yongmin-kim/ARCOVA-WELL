import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../providers/wellness_providers.dart';
import 'onboarding_screen.dart';

/// Google sign-in or continue-as-guest. Reuses the existing [AuthService].
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user != null) {
        await ref.read(wellnessControllerProvider.notifier).adoptAuthUser(
              name: user.displayName ?? 'You',
              email: user.email ?? '',
            );
      }
      _next();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in failed. You can continue as a guest.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('Sign in', style: theme.textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                'Connect to securely back up your wellness history across devices. You can also continue without an account.',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              if (_busy)
                const Center(child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ))
              else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: AppTheme.surfaceStrongColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _next,
                  child: const Text('Continue as Guest'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
