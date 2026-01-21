import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform-specific security features
class PlatformSecurity {
  /// Get current platform
  static TargetPlatform get platform {
    if (kIsWeb) {
      return TargetPlatform.web; // Custom value for web
    }
    return Theme.of(getCurrentContext()).platform;
  }

  static BuildContext getCurrentContext() {
    // This is a placeholder - actual implementation depends on context
    throw UnimplementedError('Use MediaQuery.platform instead');
  }

  /// Check if platform supports biometric authentication
  static bool supportsBiometrics() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS;
  }

  /// Check if platform supports secure storage
  static bool supportsSecureStorage() {
    if (kIsWeb) return false; // Web uses encrypted localStorage
    return true;
  }

  /// Check if platform supports screenshot prevention
  static bool supportsScreenshotPrevention() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isWindows;
  }

  /// Check if platform is mobile
  static bool isMobile() {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if platform is desktop
  static bool isDesktop() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Get platform name for logging
  static String getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Get available auth methods for platform
  static List<String> getAvailableAuthMethods() {
    final methods = <String>['Master Password'];

    if (supportsBiometrics()) {
      if (Platform.isAndroid || Platform.isIOS) {
        methods.add('Biometric (Fingerprint/Face)');
      } else if (Platform.isWindows) {
        methods.add('Windows Hello');
      } else if (Platform.isMacOS) {
        methods.add('Touch ID');
      }
    }

    return methods;
  }
}
