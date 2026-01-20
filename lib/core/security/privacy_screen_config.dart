/// Configuration for privacy and security features
class PrivacyScreenConfig {
  final bool privacyScreenEnabled;
  final bool autoLockEnabled;
  final Duration autoLockTimeout;

  PrivacyScreenConfig({
    this.privacyScreenEnabled = false,
    this.autoLockEnabled = false,
    this.autoLockTimeout = const Duration(minutes: 1),
  });

  PrivacyScreenConfig copyWith({
    bool? privacyScreenEnabled,
    bool? autoLockEnabled,
    Duration? autoLockTimeout,
  }) {
    return PrivacyScreenConfig(
      privacyScreenEnabled: privacyScreenEnabled ?? this.privacyScreenEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
    );
  }
}
