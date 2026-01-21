import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/features/auth/auth_service.dart';

/// Provider for AuthService singleton
/// Note: AuthService must be initialized in main() before use
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Provider for auth state (locked/unlocked)
final authStateProvider = StateProvider<bool>((ref) {
  return false;
});
