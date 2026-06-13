import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/services/premium_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../providers/wellness_providers.dart';
import 'data_disclosure_screen.dart';
import 'medical_disclaimer_screen.dart';

// IMPORTANT: must be false before any production release.
const bool kTestMode = false;

const String _kPrivacyPolicyUrl =
    'https://app.notion.com/p/Privacy-Policy-One-Place-332e1199e4dd80afa91af46bb8e3c3f3?source=copy_link';
const String _kTermsUrl =
    'https://app.notion.com/p/Terms-of-Service-One-Place-332e1199e4dd805ba8e6e398af15ab96?source=copy_link';

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

  Future<void> _testFirebaseConnection() async {
    _toast('Testing Firebase connection…');
    try {
      final userAsync = ref.read(currentUserProvider);
      final uid = userAsync.maybeWhen(data: (u) => u?.uid, orElse: () => null);
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid ?? '_connectivity_probe');
      await docRef.get().timeout(const Duration(seconds: 8));
      _toast('Firebase connected — Firestore is reachable ✓');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _toast('Firebase reachable — sign in to access your data');
      } else {
        _toast('Firebase error: ${e.code}');
      }
    } catch (e) {
      _toast('Connection failed: $e');
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
    final userAsync = ref.read(currentUserProvider);
    final isLoggedIn = userAsync.maybeWhen(data: (u) => u != null, orElse: () => false);
    final isPremium = ref.read(premiumStatusProvider);
    final hasCloud = isLoggedIn && isPremium;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Wipe all data?'),
        content: Text(
          hasCloud
              ? 'This permanently deletes your local data AND your cloud backup. This cannot be undone.'
              : 'This permanently deletes your locally stored health, mood, and briefing history on this device. This cannot be undone.',
        ),
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
    if (ok != true) return;

    if (hasCloud) {
      try {
        await ref.read(syncServiceProvider).deleteAll();
      } catch (_) {
        // Cloud delete failed — continue with local wipe and notify.
        _toast('Cloud data could not be deleted. Local data wiped.');
      }
    }

    await ref.read(wellnessControllerProvider.notifier).wipeLocalData();
    ref.read(onboardingProvider.notifier).reset();
    _toast('All data wiped');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast('Could not open link');
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
          if (Platform.isAndroid)
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
            ])
          else
            _Section(title: 'Health Data', children: [
              const ListTile(
                leading: Icon(Icons.monitor_heart_outlined),
                title: Text('Sample wellness data'),
                subtitle: Text('Device health metrics require Android Health Connect'),
              ),
            ]),
          _Section(title: 'Cloud Backup', children: [
            ListTile(
              leading: const Icon(Icons.wifi_tethering),
              title: const Text('Test Firebase connection'),
              subtitle: const Text('Check Firestore reachability'),
              onTap: _testFirebaseConnection,
            ),
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
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: const Text('Data Use Disclosure'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DataDisclosureScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms of Use'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openUrl(_kTermsUrl),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openUrl(_kPrivacyPolicyUrl),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: const Text('Wipe and Reset',
                  style: TextStyle(color: AppTheme.errorColor)),
              subtitle: Text(
                loggedIn && isPremium
                    ? 'Permanently deletes local data and cloud backup'
                    : 'Permanently deletes local data',
                style: const TextStyle(color: AppTheme.errorColor),
              ),
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
