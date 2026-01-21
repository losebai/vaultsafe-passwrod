import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep app running when window is closed (optional)
    // For security, you might want to terminate immediately
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Security: Prevent screen recording
    if #available(macOS 10.15, *) {
      // Screen recording detection
      let screens = NSScreen.screens
      _ = screens.map { screen in
        // You can add logic to detect screen recording here
      }
    }
  }

  // Handle lock screen / sleep events
  override func applicationDidResignActive(_ notification: Notification) {
    // Trigger app lock when app loses focus
    NotificationCenter.default.post(name: NSNotification.Name("AppLock"), object: nil)
  }
}
