import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/features/passwords/add_password_screen.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/platform/platform_service.dart';

/// 密码详情界面 - 显示和复制密码
class PasswordDetailScreen extends ConsumerStatefulWidget {
  final PasswordEntry entry;

  const PasswordDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends ConsumerState<PasswordDetailScreen> {
  bool _passwordVisible = false;
  String? _decryptedPassword;

  @override
  void initState() {
    super.initState();
    _decryptPassword();
  }

  Future<void> _decryptPassword() async {
    final authService = ref.read(authServiceProvider);
    final masterKey = authService.masterKey;

    if (masterKey != null) {
      try {
        final decrypted = EncryptionService.decrypt(widget.entry.encryptedPassword, masterKey);
        setState(() {
          _decryptedPassword = decrypted;
        });
      } catch (e) {
        // Handle decryption error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editPassword(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title card
          Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                child: Text(
                  widget.entry.title[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              title: Text(
                widget.entry.title,
                style: theme.textTheme.titleLarge,
              ),
              subtitle: Text(widget.entry.website),
            ),
          ),
          const SizedBox(height: 16),

          // Username
          _buildDetailTile(
            icon: Icons.person,
            label: '用户名',
            value: widget.entry.username,
            onCopy: () => _copyToClipboard(widget.entry.username, '用户名'),
          ),

          // Password
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('密码'),
              subtitle: _passwordVisible && _decryptedPassword != null
                  ? Text(_decryptedPassword!)
                  : const Text('••••••••'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _decryptedPassword != null
                        ? () => _copyToClipboard(_decryptedPassword!, '密码')
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // Website
          _buildDetailTile(
            icon: Icons.language,
            label: '网站',
            value: widget.entry.website,
            onCopy: () => _copyToClipboard(widget.entry.website, '网站'),
          ),

          // Notes
          if (widget.entry.notes != null && widget.entry.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '备注',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.entry.notes!),
                  ],
                ),
              ),
            ),
          ],

          // Metadata
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '元数据',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('创建时间'),
                  subtitle: Text(_formatDate(widget.entry.createdAt)),
                ),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('最后修改'),
                  subtitle: Text(_formatDate(widget.entry.updatedAt)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
        trailing: onCopy != null
            ? IconButton(
                icon: const Icon(Icons.copy),
                onPressed: onCopy,
              )
            : null,
      ),
    );
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label 已复制到剪贴板'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Auto-clear clipboard after 30 seconds for security
    Future.delayed(const Duration(seconds: 30), () {
      PlatformService().clearClipboard();
    });
  }

  void _editPassword(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPasswordScreen(entry: widget.entry),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除密码'),
          content: const Text('确定要删除这个密码吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(passwordEntriesProvider.notifier).deleteEntry(widget.entry.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码已删除')),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
