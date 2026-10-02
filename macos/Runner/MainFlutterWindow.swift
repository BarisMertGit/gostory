import Cocoa
import FlutterMacOS
import CoreLocation

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(NSRect(origin: windowFrame.origin, size: NSSize(width: 430, height: 860)), display: true)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    let permissions = FlutterMethodChannel(name: "com.gostory/permissions", binaryMessenger: flutterViewController.engine.binaryMessenger)
    permissions.setMethodCallHandler { call, result in
      if call.method == "markRequested" {
        result(nil)
      } else if call.method == "status", call.arguments as? String == "location" {
        switch CLLocationManager().authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: result("granted")
        case .denied: result("blocked")
        case .restricted: result("restricted")
        default: result("denied")
        }
      } else if call.method == "status" {
        result("restricted")
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
