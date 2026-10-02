import Flutter
import UIKit
import AVFoundation
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GoStoryPermissions") else { return }
    let channel = FlutterMethodChannel(name: "com.gostory/permissions", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard let permission = call.arguments as? String else {
        result(FlutterError(code: "invalid_argument", message: "Permission required", details: nil))
        return
      }
      if call.method == "markRequested" { result(nil); return }
      guard call.method == "status" else { result(FlutterMethodNotImplemented); return }
      if permission == "camera" {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: result("granted")
        case .notDetermined: result("denied")
        case .denied: result("blocked")
        case .restricted: result("restricted")
        @unknown default: result("restricted")
        }
      } else if permission == "location" {
        switch CLLocationManager().authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: result("granted")
        case .notDetermined: result("denied")
        case .denied: result("blocked")
        case .restricted: result("restricted")
        @unknown default: result("restricted")
        }
      } else { result(FlutterMethodNotImplemented) }
    }
  }
}
