import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/features/auth/setup_password_screen.dart';
import 'package:vaultsafe/main.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/core/security/password_verification_service.dart';


/// 认证界面 - 处理主密码输入和生物识别
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {

  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkAutoUnlock();
  }

  /// 检查是否需要自动解锁（在有效期内直接进入）
  Future<void> _checkAutoUnlock() async {
    final authService = ref.read(authServiceProvider);
    final settingsAsync = ref.read(settingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings != null && authService.isUnlockValid(settings.autoLockTimeout)) {
      if (!mounted) return;
      _navigateToHome();
    } else {
      await _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {

    // 获取已注入的 AuthService 实例
    final authService = ref.read(authServiceProvider);

    final hasPassword = await authService.hasMasterPassword();
    if (!hasPassword) {
      if (!mounted) return;
      // 跳转到设置密码页面
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SetupPasswordScreen()),
      );
      return;
    }

    final available = await authService.isBiometricAvailable();
    if (available) {
      final authenticated = await authService.authenticateWithBiometrics();
      if (authenticated && mounted) {
        // 指纹验证成功，尝试获取存储的主密码
        final storedPassword = await authService.getDecryptedMasterPassword();

        if (storedPassword != null && mounted) {
          // 有存储的主密码，直接派生密钥并进入主页
          setState(() => _isLoading = true);
          final success = await authService.verifyMasterPassword(storedPassword);

          if (!mounted) return;
          setState(() => _isLoading = false);

          if (success) {
            // 标记密码验证服务为已验证，解锁后在宽限期内不需要二次验证
            ref.read(passwordVerificationServiceProvider).markAsVerified();
            _navigateToHome();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('自动解锁失败，请手动输入密码')),
            );
          }
        } else {
          // 没有存储的主密码，显示提示让用户输入
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('指纹验证成功，请输入主密码解锁'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    }
  }

  // 主密码解锁
  Future<void> _unlock() async {
    // 1. 触发验证
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);
    final success = await authService.verifyMasterPassword(_passwordController.text);


    // 是否卸载
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // 标记密码验证服务为已验证，解锁后在宽限期内不需要二次验证
      ref.read(passwordVerificationServiceProvider).markAsVerified();
      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码错误')),
      );
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 标题
                    Text(
                      'VaultSafe',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 副标题
                    Text(
                      '输入主密码解锁',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // 密码输入框 - 75% 宽度，居中
                    Center(
                      child: SizedBox(
                        width: size.width * 0.75,
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          obscuringCharacter: '•',
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: '主密码',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _unlock(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 解锁按钮 - 75% 宽度
                    Center(
                      child: SizedBox(
                        width: size.width * 0.75,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _unlock,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '解锁',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
