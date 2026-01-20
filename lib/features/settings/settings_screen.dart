import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/features/settings/change_password_screen.dart';
import 'package:vaultafe/features/settings/sync_settings_screen.dart';
import 'package:vaultafe/shared/providers/settings_provider.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            children: [
              const _SectionHeader(title: 'Security'),
              SwitchListTile(
                title: const Text('Biometric Unlock'),
                subtitle: const Text('Use fingerprint or face to unlock'),
                value: settings.biometricEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateBiometricEnabled(value);
                },
              ),
              ListTile(
                title: const Text('Change Master Password'),
                leading: const Icon(Icons.lock_reset),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
              ),
              ListTile(
                title: const Text('Auto-lock Timeout'),
                subtitle: Text(_formatTimeout(settings.autoLockTimeout)),
                leading: const Icon(Icons.timer),
                onTap: () => _showTimeoutDialog(context, ref, settings.autoLockTimeout),
              ),

              const _SectionHeader(title: 'Sync'),
              SwitchListTile(
                title: const Text('Enable Sync'),
                subtitle: const Text('Synchronize encrypted data across devices'),
                value: settings.syncEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateSyncEnabled(value);
                  if (value) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SyncSettingsScreen()),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Sync Configuration'),
                subtitle: Text(settings.syncConfig?.endpointUrl ?? 'Not configured'),
                leading: const Icon(Icons.cloud_sync),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SyncSettingsScreen()),
                  );
                },
              ),

              const _SectionHeader(title: 'Data'),
              ListTile(
                title: const Text('Export Backup'),
                subtitle: const Text('Download encrypted backup file'),
                leading: const Icon(Icons.download),
                onTap: () => _exportBackup(context, ref),
              ),
              ListTile(
                title: const Text('Import Backup'),
                subtitle: const Text('Restore from encrypted backup file'),
                leading: const Icon(Icons.upload),
                onTap: () => _importBackup(context, ref),
              ),

              const _SectionHeader(title: 'About'),
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
                leading: const Icon(Icons.info),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  String _formatTimeout(Duration timeout) {
    if (timeout.inMinutes >= 1) {
      return '${timeout.inMinutes} minute(s)';
    }
    return '${timeout.inSeconds} second(s)';
  }

  void _showTimeoutDialog(BuildContext context, WidgetRef ref, Duration current) {
    final timeouts = [
      const Duration(seconds: 30),
      const Duration(minutes: 1),
      const Duration(minutes: 5),
      const Duration(minutes: 15),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Auto-lock Timeout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: timeouts.map((timeout) {
              return RadioListTile<Duration>(
                title: Text(_formatTimeout(timeout)),
                value: timeout,
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateAutoLockTimeout(value);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    // TODO: Implement backup export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup exported')),
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    // TODO: Implement backup import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup imported')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
