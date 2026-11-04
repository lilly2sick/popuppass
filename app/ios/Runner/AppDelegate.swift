import Flutter
import UIKit

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
    guard let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "PPHaptics")?.messenger()
    else { return }
    let channel = FlutterMethodChannel(name: "com.popuppass/haptics", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "notify",
        let args = call.arguments as? [String: Any],
        let type = args["type"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      let generator = UINotificationFeedbackGenerator()
      switch type {
      case "success": generator.notificationOccurred(.success)
      case "warning": generator.notificationOccurred(.warning)
      case "error": generator.notificationOccurred(.error)
      default:
        result(false)
        return
      }
      result(true)
    }
  }
}
