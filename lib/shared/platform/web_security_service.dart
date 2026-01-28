import 'dart:html' as html;
import 'dart:js' as js;

/// Web-specific security features
class WebSecurityService {
  /// Prevent right-click context menu
  static void preventContextMenu() {
    html.document.onContextMenu.listen((event) {
      event.preventDefault();
    });
  }

  /// Prevent text selection (for security)
  static void preventTextSelection() {
    html.document.onSelectStart.listen((event) {
      final target = event.target;
      if (target is! html.InputElement && target is! html.TextAreaElement) {
        event.preventDefault();
      }
    });
  }

  /// Prevent drag and drop
  static void preventDragAndDrop() {
    html.document.onDragStart.listen((event) {
      event.preventDefault();
    });
  }

  /// Clear localStorage securely
  static void clearSecureStorage() {
    html.window.localStorage.clear();
  }

  /// Save encrypted data to localStorage
  static void saveToStorage(String key, String encryptedData) {
    html.window.localStorage[key] = encryptedData;
  }

  /// Load encrypted data from localStorage
  static String? loadFromStorage(String key) {
    return html.window.localStorage[key];
  }

  /// Check if running in PWA mode
  static bool isPWA() {
    return html.window.matchMedia('(display-mode: standalone)').matches ||
           js.context.callMethod('matchMedia', ['(display-mode: standalone)']).matches;
  }

  /// Install service worker for offline support
  static void installServiceWorker() {
    if (js.context.hasProperty('serviceWorker')) {
      final sw = js.context['serviceWorker'];
      sw.callMethod('register', ['flutter_service_worker.js']);
    }
  }

  /// Warn before closing with unsaved changes
  static void enableCloseWarning(String message) {
    html.window.onBeforeUnload.listen((event) {
      event.preventDefault();
    });
  }

  /// Disable close warning
  static void disableCloseWarning() {
  }

  /// Check if browser supports crypto API
  static bool supportsCryptoAPI() {
    return js.context.hasProperty('crypto') && js.context['crypto']['subtle'] != null;
  }

  /// Initialize web security measures
  static void initialize() {
    preventContextMenu();
    preventDragAndDrop();
    // Note: Text selection prevention is optional as it affects UX
    // preventTextSelection();
  }
}
