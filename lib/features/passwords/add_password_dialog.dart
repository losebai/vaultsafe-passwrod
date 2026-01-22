import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/utils/password_generator.dart';

/// 添加密码对话框
class AddPasswordDialog extends ConsumerStatefulWidget {
  const AddPasswordDialog({super.key});

  @override
  ConsumerState<AddPasswordDialog> createState() => _AddPasswordDialogState();
}

class _AddPasswordDialogState extends ConsumerState<AddPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _websiteController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _notesController;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _websiteController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '添加密码',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 表单内容（使用 SingleChildScrollView 防止溢出）
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 标题
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '标题',
                          hintText: '例如：Google 账号',
                          prefixIcon: Icon(Icons.title),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入标题';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 网站
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: '网站',
                          hintText: '例如：https://google.com',
                          prefixIcon: Icon(Icons.language),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入网站';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 用户名
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: '用户名 / 邮箱',
                          prefixIcon: Icon(Icons.person),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入用户名';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 密码
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: '密码',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _generatePassword,
                                tooltip: '生成密码',
                              ),
                              IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                                tooltip: '显示/隐藏密码',
                              ),
                            ],
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入密码';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 备注
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: '备注（可选）',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // 密码强度指示器
                      if (_passwordController.text.isNotEmpty)
                        _buildPasswordStrengthIndicator(theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存密码'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 密码强度指示器
  Widget _buildPasswordStrengthIndicator(ThemeData theme) {
    final password = _passwordController.text;
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    String strengthText;
    Color strengthColor;

    if (strength <= 2) {
      strengthText = '弱';
      strengthColor = theme.colorScheme.error;
    } else if (strength <= 4) {
      strengthText = '中';
      strengthColor = theme.colorScheme.primary;
    } else {
      strengthText = '强';
      strengthColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            strength <= 2 ? Icons.warning : Icons.check_circle,
            size: 16,
            color: strengthColor,
          ),
          const SizedBox(width: 8),
          Text(
            '密码强度: $strengthText',
            style: theme.textTheme.bodySmall?.copyWith(
              color: strengthColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // 强度条
          ...List.generate(3, (index) {
            final isActive = index < (strength / 2).ceil();
            return Container(
              margin: const EdgeInsets.only(left: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? strengthColor : theme.colorScheme.outline.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final masterKey = authService.masterKey;

      if (masterKey == null) {
        throw Exception('密码库已锁定');
      }

      final encrypted = EncryptionService.encrypt(_passwordController.text, masterKey);

      final entry = PasswordEntry(
        id: const Uuid().v4(),
        title: _titleController.text,
        website: _websiteController.text,
        username: _usernameController.text,
        encryptedPassword: encrypted,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        groupId: 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(passwordEntriesProvider.notifier).addEntry(entry);

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已保存')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('错误: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _generatePassword() {
    final password = PasswordGenerator.generate(
      length: 16,
      includeUppercase: true,
      includeLowercase: true,
      includeNumbers: true,
      includeSymbols: true,
    );

    setState(() {
      _passwordController.text = password;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _websiteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
