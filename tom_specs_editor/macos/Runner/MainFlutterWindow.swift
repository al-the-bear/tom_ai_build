import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    // Default the window to 1920x1080, keeping its current top-left origin.
    let currentFrame = self.frame
    let defaultSize = NSSize(width: 1920, height: 1080)
    let originY = currentFrame.origin.y + currentFrame.size.height - defaultSize.height
    let windowFrame = NSRect(
      x: currentFrame.origin.x,
      y: originY,
      width: defaultSize.width,
      height: defaultSize.height)
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
