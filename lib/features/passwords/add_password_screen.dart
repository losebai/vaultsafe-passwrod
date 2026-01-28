import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:vaultsafe/shared/models/password_entry.dart';
import 'package:vaultsafe/shared/providers/password_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/utils/password_generator.dart';

/// 添加或编辑密码界面
class AddPasswordScreen extends ConsumerStatefulWidget {
  final PasswordEntry? entry;

  const AddPasswordScreen({super.key, this.entry});

  @override
  ConsumerState<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends ConsumerState<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _websiteController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _notesController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEditMode = false;
  bool _syncEnabled = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.entry != null;
    _syncEnabled = widget.entry?.syncEnabled ?? true;

    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _websiteController = TextEditingController(text: widget.entry?.website ?? '');
    _usernameController = TextEditingController(text: widget.entry?.username ?? '');
    _passwordController = TextEditingController(text: '');
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '编辑密码' : '添加密码'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
                hintText: '例如：Google 账号',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'HOST',
                border: OutlineInputBorder(),
                hintText: '例如：https://google.com',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入HOST';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名 / 邮箱',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: _isEditMode ? '新密码（留空保持不变）' : '密码',
                border: const OutlineInputBorder(),
                suffixIcon: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _generatePassword,
                        tooltip: '生成密码',
                      ),
                      IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              validator: (value) {
                if (!_isEditMode && (value == null || value.isEmpty)) {
                  return '请输入密码';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用同步'),
              subtitle: const Text('关闭后此密码仅保存在本地，不会同步到云端'),
              value: _syncEnabled,
              onChanged: (value) {
                setState(() {
                  _syncEnabled = value;
                });
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditMode ? '更新密码' : '保存密码'),
            ),
          ],
        ),
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
        id: widget.entry?.id ?? const Uuid().v4(),
        title: _titleController.text,
        website: _websiteController.text,
        username: _usernameController.text,
        encryptedPassword: encrypted,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        groupId: widget.entry?.groupId ?? 'default',
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        syncEnabled: _syncEnabled,
      );

      if (_isEditMode) {
        await ref.read(passwordEntriesProvider.notifier).updateEntry(entry);
      } else {
        await ref.read(passwordEntriesProvider.notifier).addEntry(entry);
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditMode ? '密码已更新' : '密码已保存')),
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

    _passwordController.text = password;
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
