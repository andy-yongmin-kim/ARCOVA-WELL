import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/services/premium_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../providers/wellness_providers.dart';
import 'medical_disclaimer_screen.dart';

/// ⚠️ Pre-release flag — bypasses real payment so premium can be toggled
/// during development. MUST be set to `false` before any production release.
const bool kTestMode = true;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _initializedPayments = false;

  @override
  void initState() {
    super.initState();
    if (!kTestMode) {
      final payment = ref.read(paymentServiceProvider);
      payment.onStatusChanged = (status, message) {
        if (status == PaymentStatus.purchased) {
          ref.read(premiumStatusProvider.notifier).markPaid();
        }
        if (message != null && mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      };
      payment.initialize().then((_) => _initializedPayments = true);
    }
  }

  Future<void> _upgrade() async {
    if (kTestMode) {
      await ref.read(premiumStatusProvider.notifier).markPaid();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium unlocked (test mode)')),
        );
      }
      return;
    }
    if (!_initializedPayments) return;
    await ref.read(paymentServiceProvider).purchasePremium();
  }

  Future<void> _editProfile(String name, String email) async {
    final nameC = TextEditingController(text: name);
    final emailC = TextEditingController(text: email);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameC, decoration: const InputDecoration(hintText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: emailC, decoration: const InputDecoration(hintText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      await ref
          .read(wellnessControllerProvider.notifier)
          .updateProfile(nameC.text.trim(), emailC.text.trim());
    }
  }

  Future<void> _backupNow() async {
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    try {
      final n = await ref.read(syncServiceProvider).uploadAll();
      await ref.read(syncServiceProvider).saveUserProfile();
      ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
      _toast('Backed up $n records');
    } catch (e) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      _toast('Backup failed: $e');
    }
  }

  Future<void> _restore() async {
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    try {
      final n = await ref.read(syncServiceProvider).downloadAll();
      ref.read(wellnessControllerProvider.notifier).refreshFromLocal();
      ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
      _toast('Restored $n records');
    } catch (e) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      _toast('Restore failed: $e');
    }
  }

  Future<void> _signIn() async {
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user != null) {
        await ref.read(wellnessControllerProvider.notifier).adoptAuthUser(
              name: user.displayName ?? 'You',
              email: user.email ?? '',
            );
        _toast('Signed in as ${user.email}');
      }
    } catch (_) {
      _toast('Sign-in failed');
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    _toast('Signed out');
  }

  Future<void> _wipe() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Wipe local data?'),
        content: const Text(
            'This permanently deletes your locally stored health, mood, and briefing history on this device. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wipe'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(wellnessControllerProvider.notifier).wipeLocalData();
      ref.read(onboardingProvider.notifier).reset();
      _toast('Local data wiped');
    }
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(wellnessControllerProvider);
    final isPremium = ref.watch(premiumStatusProvider);
    final userAsync = ref.watch(currentUserProvider);
    final loggedIn = userAsync.maybeWhen(data: (u) => u != null, orElse: () => false);
    final healthConnected = ref.watch(onboardingProvider).healthConnected;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Section(title: 'Account', children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(state.profile.name),
              subtitle: Text(state.profile.email.isEmpty ? 'No email' : state.profile.email),
              trailing: TextButton(
                onPressed: () => _editProfile(state.profile.name, state.profile.email),
                child: const Text('Edit'),
              ),
            ),
            ListTile(
              leading: Icon(loggedIn ? Icons.logout : Icons.login),
              title: Text(loggedIn ? 'Sign out' : 'Sign in with Google'),
              subtitle: Text(loggedIn ? 'Backup & sync enabled' : 'Required for cloud backup'),
              onTap: loggedIn ? _signOut : _signIn,
            ),
          ]),
          _Section(title: 'Health Data', children: [
            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: Text(healthConnected ? 'Health Connect' : 'Sample data'),
              subtitle: Text(healthConnected
                  ? 'Reading real device metrics'
                  : 'Using simulated sample streams'),
              trailing: state.isConnectingHealth
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: () => ref
                          .read(wellnessControllerProvider.notifier)
                          .connectHealth(sampleFallback: !healthConnected),
                      child: const Text('Refresh'),
                    ),
            ),
          ]),
          _Section(title: 'Cloud Backup', children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Back up now'),
              enabled: loggedIn && isPremium,
              subtitle: Text(loggedIn && isPremium
                  ? 'Upload your history to the cloud'
                  : 'Requires sign-in + premium'),
              onTap: (loggedIn && isPremium) ? _backupNow : null,
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Restore from cloud'),
              enabled: loggedIn && isPremium,
              onTap: (loggedIn && isPremium) ? _restore : null,
            ),
          ]),
          _Section(title: 'Subscription', children: [
            ListTile(
              leading: Icon(isPremium ? Icons.workspace_premium : Icons.lock_outline,
                  color: isPremium ? AppTheme.tertiaryColor : null),
              title: Text(isPremium ? 'Premium active' : 'Basic (free)'),
              subtitle: Text(isPremium
                  ? 'Cloud sync & future integrations unlocked'
                  : 'Upgrade to sync across devices'),
              trailing: isPremium
                  ? null
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(96, 40)),
                      onPressed: _upgrade,
                      child: const Text('Upgrade'),
                    ),
            ),
          ]),
          _Section(title: 'Legal', children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Medical Disclaimer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MedicalDisclaimerScreen()),
              ),
            ),
            const ListTile(
              leading: Icon(Icons.description_outlined),
              title: Text('Terms of Use'),
              trailing: Icon(Icons.chevron_right),
            ),
            const ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy Policy'),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: const Text('Wipe and Reset Local Data',
                  style: TextStyle(color: AppTheme.errorColor)),
              onTap: _wipe,
            ),
          ]),
          const SizedBox(height: 16),
          Center(
            child: Text('Arcova Well · v1.0.0\n© 2026 Arcova',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Text(title.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
