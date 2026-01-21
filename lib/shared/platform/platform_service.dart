import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaultsafe/shared/platform/platform_security.dart';

/// Platform service for handling platform-specific functionality
class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.vaultsafe/platform');

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Initialize platform-specific settings
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _initAndroid();
    } else if (Platform.isIOS) {
      await _initIOS();
    } else if (Platform.isWindows) {
      await _initWindows();
    } else if (Platform.isMacOS) {
      await _initMacOS();
    }
  }

  /// Android-specific initialization
  Future<void> _initAndroid() async {
    try {
      // Prevent screenshots
      await _channel.invokeMethod('setSecureFlag', {'secure': true});
    } catch (e) {
      // Method not implemented yet
    }
  }

  /// iOS-specific initialization
  Future<void> _initIOS() async {
    try {
      // Prevent screen recording
      await _channel.invokeMethod('preventScreenRecording');
    } catch (e) {
      // Method not implemented yet
    }
  }

  /// Windows-specific initialization
  Future<void> _initWindows() async {
    try {
      // Set window security properties
      await _channel.invokeMethod('setWindowSecurity');
    } catch (e) {
      // Method not implemented yet
    }
  }

  /// macOS-specific initialization
  Future<void> _initMacOS() async {
    try {
      // Prevent screen capture
      await _channel.invokeMethod('preventScreenCapture');
    } catch (e) {
      // Method not implemented yet
    }
  }

  /// Enable privacy screen (prevent screenshots)
  Future<void> enablePrivacyScreen() async {
    if (!PlatformSecurity.supportsScreenshotPrevention()) {
      return;
    }

    try {
      await _channel.invokeMethod('enablePrivacyScreen');
    } catch (e) {
      // Fall back to platform-specific implementations
    }
  }

  /// Disable privacy screen
  Future<void> disablePrivacyScreen() async {
    try {
      await _channel.invokeMethod('disablePrivacyScreen');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear clipboard securely
  Future<void> clearClipboard() async {
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  /// Check if app is running in background
  Future<bool> isInBackground() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final result = await _channel.invokeMethod('isInBackground');
        return result == true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Minimize app (for security when idle)
  Future<void> minimizeApp() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('minimizeApp');
      } catch (e) {
        // Ignore
      }
    }
  }
}
