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
    registerSocialShare(messenger)
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

  /// Direct Instagram / Facebook Stories sharing (needs a Meta app id). Puts the
  /// image on the pasteboard under the app's sticker key, then opens its URL.
  private func registerSocialShare(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.popuppass/social", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "shareToStory",
        let args = call.arguments as? [String: Any],
        let app = args["app"] as? String,
        let path = args["path"] as? String,
        let appId = args["appId"] as? String,
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
      else {
        result(false)
        return
      }
      let scheme = app == "instagram" ? "instagram-stories" : "facebook-stories"
      let key = app == "instagram"
        ? "com.instagram.sharedSticker.backgroundImage"
        : "com.facebook.sharedSticker.backgroundImage"
      guard
        let url = URL(string: "\(scheme)://share?source_application=\(appId)"),
        UIApplication.shared.canOpenURL(url)
      else {
        result(false)
        return
      }
      var items: [String: Any] = [key: data]
      if app == "facebook" { items["com.facebook.sharedSticker.appID"] = appId }
      UIPasteboard.general.setItems([items], options: [.expirationDate: Date().addingTimeInterval(300)])
      UIApplication.shared.open(url, options: [:]) { ok in result(ok) }
    }
  }
}
