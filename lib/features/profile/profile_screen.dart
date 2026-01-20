import 'package:flutter/material.dart';
import 'package:vaultafe/shared/providers/settings_provider.dart';

/// Profile screen showing account info and device list
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'VaultSafe User',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Local encrypted storage',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Statistics
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Statistics',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.password),
                  title: Text('Total Passwords'),
                  trailing: Text('0'), // TODO: Get actual count
                ),
                const ListTile(
                  leading: Icon(Icons.folder),
                  title: Text('Groups'),
                  trailing: Text('0'),
                ),
                const ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Encryption'),
                  trailing: Text('AES-256-GCM'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security info
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Security',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.verified_user),
                  title: Text('Zero Knowledge'),
                  subtitle: Text('Your data never leaves this device unencrypted'),
                ),
                const ListTile(
                  leading: Icon(Icons.enhanced_encryption),
                  title: Text('End-to-End Encryption'),
                  subtitle: Text('All data encrypted with your master password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App info
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'About',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const ListTile(
                  title: Text('Version'),
                  trailing: Text('1.0.0'),
                ),
                const ListTile(
                  title: Text('License'),
                  trailing: Text('MIT'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
