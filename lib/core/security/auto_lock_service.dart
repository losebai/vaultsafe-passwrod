import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultsafe/shared/providers/settings_provider.dart';
import 'package:vaultsafe/shared/providers/auth_provider.dart';

/// Auto-lock service to track user activity and lock the app after inactivity
class AutoLockService {
  Timer? _lockTimer;
  DateTime? _lastActivity;
  bool _isEnabled = false;
  VoidCallback? _onLockCallback;
  Duration? _currentTimeout;

  /// Enable auto-lock with callback
  void enableAutoLock(Duration timeout, VoidCallback onLock) {
    try {
      // Cancel any existing timer first
      _lockTimer?.cancel();
      _lockTimer = null;

      _isEnabled = true;
      _onLockCallback = onLock;
      _currentTimeout = timeout;
      _lastActivity = DateTime.now();
      _startLockTimer(timeout);
    } catch (e) {
      // If enabling fails, clean up state
      _isEnabled = false;
      _lockTimer?.cancel();
      _lockTimer = null;
      rethrow;
    }
  }

  /// Disable auto-lock
  void disableAutoLock() {
    try {
      _isEnabled = false;
      _lockTimer?.cancel();
      _lockTimer = null;
      _lastActivity = null;
      _onLockCallback = null;
    } catch (e) {
      // Ignore errors during cleanup
    }
  }

  /// Start the lock timer
  void _startLockTimer(Duration timeout) {
    try {
      _lockTimer?.cancel();
      _lockTimer = Timer(timeout, _checkAndLock);
    } catch (e) {
      // If timer creation fails, try to recover
      _lockTimer = null;
    }
  }

  /// Check if should lock and execute lock callback
  void _checkAndLock() {
    try {
      if (!_isEnabled || _lastActivity == null || _currentTimeout == null) return;

      final now = DateTime.now();
      final elapsed = now.difference(_lastActivity!);

      if (elapsed >= _currentTimeout!) {
        _onLockCallback?.call();
      } else {
        // Restart timer with remaining time
        final remaining = _currentTimeout! - elapsed;
        if (remaining > Duration.zero) {
          _startLockTimer(remaining);
        }
      }
    } catch (e) {
      // If check fails, disable auto-lock to prevent continuous failures
      disableAutoLock();
    }
  }

  /// Update user activity timestamp
  void reportActivity() {
    try {
      _lastActivity = DateTime.now();
    } catch (e) {
      // Ignore errors when updating activity
    }
  }

  /// Update timeout duration
  void updateTimeout(Duration timeout) {
    try {
      _currentTimeout = timeout;
      if (_isEnabled && _lastActivity != null) {
        _startLockTimer(timeout);
      }
    } catch (e) {
      // Ignore errors when updating timeout
    }
  }

  /// Dispose the service
  void dispose() {
    try {
      disableAutoLock();
    } catch (e) {
      // Ignore errors during disposal
    }
  }
}

/// Provider for AutoLockService
final autoLockServiceProvider = Provider<AutoLockService>((ref) {
  final service = AutoLockService();

  ref.onDispose(() {
    try {
      service.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
  });

  return service;
});

/// Global holder for auto lock service instance (for keyboard listener access)
AutoLockService? _globalAutoLockService;

/// Helper to get current auto lock service
AutoLockService? get currentAutoLockService => _globalAutoLockService;

/// Set the global auto lock service
void setGlobalAutoLockService(AutoLockService service) {
  try {
    _globalAutoLockService = service;
  } catch (e) {
    // Ignore errors
  }
}

/// Clear the global auto lock service
void clearGlobalAutoLockService() {
  try {
    _globalAutoLockService = null;
  } catch (e) {
    // Ignore errors
  }
}

/// Keyboard listener widget to detect user activity
class AutoLockKeyboardListener extends ConsumerStatefulWidget {
  final Widget child;

  const AutoLockKeyboardListener({super.key, required this.child});

  @override
  ConsumerState<AutoLockKeyboardListener> createState() => _AutoLockKeyboardListenerState();
}

class _AutoLockKeyboardListenerState extends ConsumerState<AutoLockKeyboardListener> {
  final FocusNode _focusNode = FocusNode();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Store reference to the service for keyboard listener access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      try {
        setGlobalAutoLockService(ref.read(autoLockServiceProvider));
      } catch (e) {
        // Ignore errors during initialization
      }
    });

    // Request focus with error handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;
      try {
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      } catch (e) {
        // Ignore focus request errors
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _focusNode.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
    clearGlobalAutoLockService();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    try {
      if (_isDisposed) return;

      // Report activity on any key event
      if (event is! KeyUpEvent) {
        currentAutoLockService?.reportActivity();
      }
    } catch (e) {
      // Ignore event handling errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

/// Wrapper widget that enables auto-lock and wraps content with activity detection
class AutoLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AutoLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AutoLockWrapper> createState() => _AutoLockWrapperState();
}

class _AutoLockWrapperState extends ConsumerState<AutoLockWrapper> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeAutoLock();
  }

  void _initializeAutoLock() {
    if (_isDisposed) return;
    try {
      final settingsAsync = ref.read(settingsProvider);
      settingsAsync.whenData((settings) {
        if (_isDisposed) return;
        _setupAutoLock(settings.autoLockTimeout);
      });
    } catch (e) {
      // Log error but don't crash
    }
  }

  void _setupAutoLock(Duration timeout) {
    if (_isDisposed) return;
    try {
      final autoLockService = ref.read(autoLockServiceProvider);
      autoLockService.enableAutoLock(timeout, _lockApp);
    } catch (e) {
      // If setup fails, retry after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (!_isDisposed && mounted) {
          _initializeAutoLock();
        }
      });
    }
  }

  void _lockApp() {
    if (_isDisposed || !mounted) return;

    try {
      // Lock the app by clearing master key
      final authService = ref.read(authServiceProvider);
      authService.lock();

      // Navigate back to auth screen using named route
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      // If navigation fails, try alternative method
      if (mounted) {
        try {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const _AuthScreenPlaceholder()),
            (route) => false,
          );
        } catch (e2) {
          // Last resort: just lock the auth service
          try {
            ref.read(authServiceProvider).lock();
          } catch (_) {}
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with keyboard listener and activity detection
    return Listener(
      // Listener captures all pointer events without interfering with gestures
      onPointerDown: (_) => _reportActivity(),
      onPointerMove: (_) => _reportActivity(),
      behavior: HitTestBehavior.translucent,
      child: AutoLockKeyboardListener(
        child: widget.child,
      ),
    );
  }

  void _reportActivity() {
    if (_isDisposed) return;
    try {
      ref.read(autoLockServiceProvider).reportActivity();
    } catch (e) {
      // Ignore activity reporting errors
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      ref.read(autoLockServiceProvider).disableAutoLock();
    } catch (e) {
      // Ignore disposal errors
    }
    super.dispose();
  }
}

/// Placeholder for auth screen (used as fallback)
class _AuthScreenPlaceholder extends StatelessWidget {
  const _AuthScreenPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
