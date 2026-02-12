import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';

/// 设置主密码界面
class SetupPasswordScreen extends ConsumerStatefulWidget {

  /// 构造函数
  const SetupPasswordScreen({super.key});

  @override
  ConsumerState<SetupPasswordScreen> createState() => _SetupPasswordScreenState();
}

class _SetupPasswordScreenState extends ConsumerState<SetupPasswordScreen> {

  /// 主密码输入框控制器
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  /// 表单键
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _enableBiometricUnlock = false;
  bool _biometricAvailable = false;
  bool _isCheckingBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  /// 检查生物识别是否可用
  Future<void> _checkBiometricAvailability() async {
    setState(() => _isCheckingBiometric = true);

    final authService = ref.read(authServiceProvider);
    final available = await authService.isBiometricAvailable();

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _isCheckingBiometric = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置 VaultSafe'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.security_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '创建您的主密码',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '此密码将加密您所有数据。请设置一个强密码并牢记 - 它无法被恢复！',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '主密码',
                    border: OutlineInputBorder(),
                    helperText: '至少 8 个字符',
                  ),
                  obscureText: true,
                  obscuringCharacter: '•',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    if (value.length < 8) {
                      return '密码至少需要 8 个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  decoration: const InputDecoration(
                    labelText: '确认密码',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  obscuringCharacter: '•',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请确认密码';
                    }
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),
                // Show biometric unlock option if available
                if (!_isCheckingBiometric && _biometricAvailable) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _enableBiometricUnlock,
                    onChanged: (value) => setState(() => _enableBiometricUnlock = value ?? false),
                    title: const Text('启用指纹直接解锁'),
                    subtitle: const Text('启用后，可以使用指纹快速解锁，无需输入主密码'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.platform,
                  ),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _isLoading ? null : _setup,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('创建密码库'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);
    await authService.setupMasterPasswordWithBiometric(
      _passwordController.text,
      _enableBiometricUnlock,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    // 导航到主界面
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
