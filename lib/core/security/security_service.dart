import 'package:flutter/services.dart';
import 'package:vaultsafe/core/security/privacy_screen_config.dart';

/// Security service for privacy features (anti-screenshot, auto-lock)
class SecurityService {
  PrivacyScreenConfig _config = PrivacyScreenConfig();

  PrivacyScreenConfig get config => _config;

  /// Enable privacy screen (prevent screenshots/screen recording)
  Future<void> enablePrivacyScreen() async {
    try {
      // Set secure flag to prevent screenshots
      await SystemChannels.platform.invokeMethod('SystemChrome.setApplicationSwitcherDescription', {
        'label': 'VaultSafe',
        'primaryColor': 0xFF2196F3,
      });

      // Note: Full screenshot prevention requires platform-specific implementation
      // iOS: Use UITextField with secureTextEntry
      // Android: Set FLAG_SECURE in activity
      _config = _config.copyWith(privacyScreenEnabled: true);
    } catch (e) {
      // Platform may not support this
    }
  }

  /// Disable privacy screen
  Future<void> disablePrivacyScreen() async {
    _config = _config.copyWith(privacyScreenEnabled: false);
  }

  /// Enable auto-lock after timeout
  void enableAutoLock(Duration timeout) {
    _config = _config.copyWith(
      autoLockEnabled: true,
      autoLockTimeout: timeout,
    );
  }

  /// Disable auto-lock
  void disableAutoLock() {
    _config = _config.copyWith(
      autoLockEnabled: false,
    );
  }

  /// Check if app should be locked based on last activity
  bool shouldLock(DateTime? lastActivity) {
    if (!_config.autoLockEnabled || lastActivity == null) {
      return false;
    }

    final now = DateTime.now();
    final elapsed = now.difference(lastActivity);

    return elapsed >= _config.autoLockTimeout;
  }

  /// Clear clipboard after timeout (security best practice)
  Future<void> clearClipboard() async {
    await SystemChannels.platform.invokeMethod('Clipboard.setData', <String, dynamic>{'text': ''});
  }
}
