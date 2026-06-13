import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'health_permission_screen.dart';

class _Page {
  final IconData icon;
  final String title;
  final String body;
  const _Page(this.icon, this.title, this.body);
}

List<_Page> _buildPages() {
  final firstPageBody = Platform.isAndroid
      ? 'Arcova aggregates your sleep, steps, heart rate, and mood into a clear daily picture.'
      : 'Arcova tracks your mood and generates personalized daily insights powered by AI.';

  return [
    _Page(Icons.insights_outlined, 'Understand your wellness patterns', firstPageBody),
    _Page(Icons.bolt_outlined, 'Turn insight into action',
        'Each morning you get a personalized briefing with a few practical, achievable actions.'),
    _Page(Icons.health_and_safety_outlined, 'Wellness, not diagnosis',
        'Arcova supports healthy habits. It is not a medical device and does not diagnose conditions.'),
  ];
}

/// Three-page onboarding carousel.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  late final List<_Page> _pages;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
          duration: AppTheme.animationNormal, curve: Curves.easeInOut);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HealthPermissionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon, size: 56, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 36),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 14),
                        Text(p.body,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: AppTheme.animationFast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.primaryColor
                              : AppTheme.surfaceStrongColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Continue' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
