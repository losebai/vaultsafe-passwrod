import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultafe/core/sync/sync_auth_type.dart';
import 'package:vaultafe/core/sync/sync_interval.dart';
import 'package:vaultafe/core/sync/sync_service.dart';
import 'package:vaultafe/shared/providers/settings_provider.dart';

/// Sync settings screen for configuring third-party sync
class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  final _endpointController = TextEditingController();
  final _tokenController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  SyncAuthType _authType = SyncAuthType.bearer;
  SyncInterval _interval = SyncInterval.none;
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Configure your own sync server. All data is encrypted before upload.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'Endpoint URL',
                border: OutlineInputBorder(),
                hintText: 'https://your-server.com/api/v1/sync',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter endpoint URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SyncAuthType>(
              value: _authType,
              decoration: const InputDecoration(
                labelText: 'Authentication',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: SyncAuthType.bearer, child: Text('Bearer Token')),
                DropdownMenuItem(value: SyncAuthType.basic, child: Text('Basic Auth')),
                DropdownMenuItem(value: SyncAuthType.custom, child: Text('Custom Headers')),
              ],
              onChanged: (value) {
                setState(() => _authType = value!);
              },
            ),
            const SizedBox(height: 16),
            if (_authType == SyncAuthType.bearer)
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Bearer Token',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            if (_authType == SyncAuthType.basic) ...[
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<SyncInterval>(
              value: _interval,
              decoration: const InputDecoration(
                labelText: 'Auto-sync Interval',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: SyncInterval.none, child: Text('Manual only')),
                DropdownMenuItem(value: SyncInterval.every5Min, child: Text('Every 5 minutes')),
                DropdownMenuItem(value: SyncInterval.every15Min, child: Text('Every 15 minutes')),
                DropdownMenuItem(value: SyncInterval.hourly, child: Text('Hourly')),
              ],
              onChanged: (value) {
                setState(() => _interval = value!);
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find),
              label: const Text('Test Connection'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final syncService = SyncService();
      await syncService.init(SyncConfig(
        enabled: true,
        endpointUrl: _endpointController.text,
        authType: _authType,
        token: _tokenController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        interval: _interval,
      ));

      final success = await syncService.testConnection();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Connection successful!' : 'Connection failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final config = SyncConfig(
      enabled: true,
      endpointUrl: _endpointController.text,
      authType: _authType,
      token: _authType == SyncAuthType.bearer ? _tokenController.text : null,
      username: _authType == SyncAuthType.basic ? _usernameController.text : null,
      password: _authType == SyncAuthType.basic ? _passwordController.text : null,
      interval: _interval,
    );

    ref.read(settingsProvider.notifier).updateSyncConfig(config);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync settings saved')),
    );
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
