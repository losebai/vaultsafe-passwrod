import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/features/auth/auth_service.dart';

/// AuthService 单例提供者
/// 注意：AuthService 必须在使用前在 main() 中初始化
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// 认证状态提供者（已锁定/未锁定）
final authStateProvider = StateProvider<bool>((ref) {
  return false;
});
