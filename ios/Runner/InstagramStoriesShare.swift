import Flutter
import UIKit

/// Shares straight into Instagram's Stories composer, bypassing the
/// system share sheet entirely - per Instagram's documented contract
/// (no public SDK for this, just a URL scheme plus a pasteboard
/// handoff): write the background image to `UIPasteboard` under
/// Instagram's own reserved keys, with a short expiration so it doesn't
/// linger on the clipboard, then open `instagram-stories://share`.
/// Instagram picks the image straight back up from the pasteboard the
/// moment it opens. iOS only - Android has no equivalent contract.
enum InstagramStoriesShare {
  private static let urlScheme = "instagram-stories://share"
  private static let pasteboardLifetime: TimeInterval = 60 * 5

  static func register(with registrar: FlutterPluginRegistrar) {
    FlutterMethodChannel(
      name: "com.giglab.kaunti47/instagram_stories",
      binaryMessenger: registrar.messenger()
    ).setMethodCallHandler { call, result in
      switch call.method {
      case "isAvailable":
        result(isAvailable())
      case "share":
        share(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func isAvailable() -> Bool {
    guard let url = URL(string: urlScheme) else { return false }
    return UIApplication.shared.canOpenURL(url)
  }

  private static func share(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let url = URL(string: urlScheme), UIApplication.shared.canOpenURL(url) else {
      result(false)
      return
    }
    guard
      let args = call.arguments as? [String: Any],
      let imageData = args["image"] as? FlutterStandardTypedData
    else {
      result(
        FlutterError(code: "bad_args", message: "Missing image data.", details: nil)
      )
      return
    }

    var pasteboardItem: [String: Any] = [
      "com.instagram.sharedSticker.backgroundImage": imageData.data
    ]
    if let topColor = args["backgroundTopColor"] as? String {
      pasteboardItem["com.instagram.sharedSticker.backgroundTopColor"] = topColor
    }
    if let bottomColor = args["backgroundBottomColor"] as? String {
      pasteboardItem["com.instagram.sharedSticker.backgroundBottomColor"] = bottomColor
    }
    if let attributionLink = args["attributionLink"] as? String {
      pasteboardItem["com.instagram.sharedSticker.contentURL"] = attributionLink
    }

    UIPasteboard.general.setItems(
      [pasteboardItem],
      options: [.expirationDate: Date().addingTimeInterval(pasteboardLifetime)]
    )
    UIApplication.shared.open(url, options: [:]) { success in
      result(success)
    }
  }
}
