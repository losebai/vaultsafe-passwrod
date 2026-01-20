import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/features/auth/auth_service.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for auth state (locked/unlocked)
final authStateProvider = StateProvider<bool>((ref) {
  return false;
});
