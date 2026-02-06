import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/features/passwords/add_password_screen.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/platform/platform_service.dart';
import 'package:vaultsafe/core/logging/log_service.dart';
import 'package:vaultsafe/core/security/password_verification_service.dart';

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
        // 忽略解密错误，保持密码隐藏状态
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
            onPressed: () => _editPassword(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(5),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                child: Text(
                  widget.entry.title.isNotEmpty ? widget.entry.title[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              title: Text(
                widget.entry.title,
                style: theme.textTheme.titleLarge,
              ),
              subtitle: Row(
                children: [
                  Icon(widget.entry.type.icon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    widget.entry.type.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildDetailTile(
            icon: Icons.person,
            label: widget.entry.type.usernameLabel,
            value: widget.entry.username,
            onCopy: () => _copyToClipboard(widget.entry.username, widget.entry.type.usernameLabel),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.lock),
              title: Text(widget.entry.type.passwordLabel),
              subtitle: _passwordVisible && _decryptedPassword != null
                  ? Text(_decryptedPassword!,
                      maxLines: widget.entry.type.isPasswordMultiline ? null : 1,
                      overflow: widget.entry.type.isPasswordMultiline ? null : TextOverflow.ellipsis)
                  : const Text('••••••••'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => _togglePasswordVisibility(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _decryptedPassword != null
                        ? () => _copyPassword()
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // Only show website field if it's not empty or required
          if (widget.entry.website.isNotEmpty || widget.entry.type.isWebsiteRequired)
            _buildDetailTile(
              icon: Icons.language,
              label: widget.entry.type.websiteLabel,
              value: widget.entry.website,
              onCopy: () => _copyToClipboard(widget.entry.website, widget.entry.type.websiteLabel),
            ),

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
                  leading: Icon(
                    widget.entry.syncEnabled ? Icons.sync : Icons.sync_disabled,
                    color: widget.entry.syncEnabled ? Colors.green : Colors.grey,
                  ),
                  title: const Text('同步状态'),
                  subtitle: Text(widget.entry.syncEnabled ? '已启用同步' : '仅本地保存，不同步'),
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

    // 记录用户操作日志
    log.i('复制${widget.entry.title}的$label', source: 'UserOperation');

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

  /// 切换密码可见性（需要验证）
  Future<void> _togglePasswordVisibility() async {
    // 如果要显示密码，需要验证
    if (!_passwordVisible) {
      final verified = await requestPasswordVerification(
        context,
        ref,
        reason: '查看密码',
      );

      if (!verified) {
        return; // 验证失败或取消
      }
    }

    if (mounted) {
      setState(() {
        _passwordVisible = !_passwordVisible;
      });
    }
  }

  /// 复制密码（需要验证）
  Future<void> _copyPassword() async {
    // 验证主密码
    final verified = await requestPasswordVerification(
      context,
      ref,
      reason: '复制密码',
    );

    if (!verified) {
      return; // 验证失败或取消
    }

    if (_decryptedPassword != null && mounted) {
      await _copyToClipboard(_decryptedPassword!, '密码');
    }
  }

  /// 编辑密码（需要验证）
  Future<void> _editPassword() async {
    // 验证主密码
    final verified = await requestPasswordVerification(
      context,
      ref,
      reason: '编辑密码',
    );

    if (!verified || !mounted) {
      return; // 验证失败或取消
    }

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
