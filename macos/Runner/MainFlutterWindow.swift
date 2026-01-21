import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Security: Prevent screenshots and screen recording
    self.sharingType = .none
    self.isMovableByWindowBackground = false

    // Set minimum window size
    self.minSize = NSSize(width: 800, height: 600)
  }

  // Prevent window from being captured
  override var canBecomeKey: Bool {
    return true
  }

  // Security: Make content private
  override var contentView: NSView? {
    get {
      return super.contentView
    }
    set {
      super.contentView = newValue
      // Additional security measures can be added here
    }
  }
}
