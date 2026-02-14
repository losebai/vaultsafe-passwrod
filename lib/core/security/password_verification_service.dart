import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';
import 'package:vaultsafe/shared/widgets/master_password_dialog.dart';
import 'package:vaultsafe/core/encryption/encryption_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:typed_data';

/// 密码验证服务 - 管理敏感操作时的主密码验证
class PasswordVerificationService {
  DateTime? _lastVerificationTime;
  bool _isVerified = false;
  bool _isEnabled = true;

  /// 检查是否需要验证
  bool needsVerification(Duration timeout) {
    if (!_isEnabled) return false;
    if (!_isVerified || _lastVerificationTime == null) return true;

    final elapsed = DateTime.now().difference(_lastVerificationTime!);
    return elapsed >= timeout;
  }

  /// 标记为已验证
  void markAsVerified() {
    _lastVerificationTime = DateTime.now();
    _isVerified = true;
  }

  /// 清除验证状态（用于手动登出等场景）
  void clearVerification() {
    _lastVerificationTime = null;
    _isVerified = false;
  }

  /// 启用/禁用验证
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      clearVerification();
    }
  }

  /// 请求验证（如果需要）
  /// 返回 true 表示验证成功或无需验证，false 表示验证失败或取消
  Future<bool> requestVerification(
    BuildContext context,
    WidgetRef ref, {
    String? reason,
  }) async {
    // 获取当前设置
    final settingsAsync = ref.read(settingsProvider);
    final Duration timeout;

    final settings = settingsAsync.valueOrNull;
    if (settings != null) {
      timeout = settings.passwordVerificationTimeout;
    } else {
      // 如果设置未加载，使用默认值
      timeout = const Duration(seconds: 30);
    }

    // 检查是否需要验证
    if (!needsVerification(timeout)) {
      return true;
    }

    // 需要验证，尝试使用生物识别（如果启用了指纹完全解锁）
    return await _performVerification(context, ref, settings, reason);
  }

  /// 执行验证（支持指纹完全解锁）
  Future<bool> _performVerification(
    BuildContext context,
    WidgetRef ref,
    dynamic settings,
    String? reason,
  ) async {
    // 如果启用了指纹完全解锁，优先使用生物识别
    if (settings?.biometricFullUnlock == true) {
      final biometricVerified = await _tryBiometricVerification();
      if (biometricVerified) {
        markAsVerified();
        return true;
      }
      // 生物识别失败/取消，继续尝试主密码验证
    }

    // 检查 context 是否仍然有效
    if (!context.mounted) {
      return false;
    }

    // 使用主密码验证
    return await _showVerificationDialog(context, ref, reason);
  }

  /// 尝试使用生物识别验证
  Future<bool> _tryBiometricVerification() async {
    try {
      final localAuth = LocalAuthentication();
      final isAuthenticated = await localAuth.authenticate(
        localizedReason: '请验证以继续操作',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  /// 显示验证对话框
  Future<bool> _showVerificationDialog(
    BuildContext context,
    WidgetRef ref,
    String? reason,
  ) async {
    const storage = FlutterSecureStorage();

    // 读取salt
    final salt = await storage.read(key: 'master_salt');
    if (salt == null) {
      return false;
    }

    // 检查 context 是否仍然有效
    if (!context.mounted) {
      return false;
    }

    final saltBytes = Uint8List.fromList(
      List.generate(salt.length ~/ 2, (i) => int.parse(salt.substring(i * 2, i * 2 + 2), radix: 16)),
    );

    // 显示对话框让用户输入密码
    final password = await showMasterPasswordDialog(
      context,
      title: reason ?? '验证主密码',
      hintText: '请输入主密码以继续',
      onVerify: (password) async {
        try {
          // 验证密码是否正确
          final authService = ref.read(authServiceProvider);
          if (!authService.isUnlocked) {
            return false;
          }

          // 使用异步密钥派生，避免 UI 卡顿
          final testKey = await EncryptionService.deriveKeyAsync(password, saltBytes);

          // 如果当前已解锁，比较密钥是否一致
          final currentKey = authService.masterKey;
          if (currentKey != null) {
            // 简单比较：使用相同的密码应该派生相同的密钥
            return _listEquals(testKey, currentKey);
          }

          return false;
        } catch (e) {
          return false;
        }
      },
    );

    if (password != null) {
      markAsVerified();
      return true;
    }

    return false;
  }

  /// 比较两个 Uint8List 是否相等
  bool _listEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 强制请求主密码验证（不支持生物识别）
  /// 用于修改主密码等必须使用主密码的场景
  Future<bool> requestMasterPasswordOnly(
    BuildContext context,
    WidgetRef ref, {
    String? reason,
  }) async {
    // 直接显示主密码验证对话框，跳过生物识别
    if (!context.mounted) {
      return false;
    }
    return await _showVerificationDialog(context, ref, reason);
  }
}

/// PasswordVerificationService 的 Provider
final passwordVerificationServiceProvider = Provider<PasswordVerificationService>((ref) {
  final service = PasswordVerificationService();

  ref.onDispose(() {
    service.clearVerification();
  });

  return service;
});

/// 辅助函数：请求密码验证
/// 用于在敏感操作前验证用户身份
/// 如果启用了指纹完全解锁，会优先使用生物识别
Future<bool> requestPasswordVerification(
  BuildContext context,
  WidgetRef ref, {
  String? reason,
}) async {
  final service = ref.read(passwordVerificationServiceProvider);
  return await service.requestVerification(context, ref, reason: reason);
}

/// 辅助函数：强制请求主密码验证（不支持生物识别）
/// 用于修改主密码等必须使用主密码的场景
Future<bool> requestMasterPasswordVerification(
  BuildContext context,
  WidgetRef ref, {
  String? reason,
}) async {
  final service = ref.read(passwordVerificationServiceProvider);
  return await service.requestMasterPasswordOnly(context, ref, reason: reason);
}
