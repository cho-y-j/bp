import Flutter
import UIKit
import MessageUI

/// 문자 작성창(MFMessageComposeViewController) 브릿지.
/// recipients / body / 이미지(또는 PDF) 첨부를 채워 작성창을 연다.
/// 문자 불가 기기(시뮬레이터 등)에서는 "unsupported" 를 반환해 Dart 폴백으로 넘긴다.
class SmsComposerPlugin: NSObject, MFMessageComposeViewControllerDelegate {
  static let channelName = "kr.workon/sms"

  private var pendingResult: FlutterResult?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let instance = SmsComposerPlugin()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "canSendText":
      result(MFMessageComposeViewController.canSendText())
    case "canSendAttachments":
      result(MFMessageComposeViewController.canSendText()
        && MFMessageComposeViewController.canSendAttachments())
    case "compose":
      compose(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func compose(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard MFMessageComposeViewController.canSendText() else {
      // 시뮬레이터/문자 불가 기기 → Dart 폴백.
      result("unsupported")
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    let recipients = args["recipients"] as? [String] ?? []
    let body = args["body"] as? String ?? ""
    let attachments = args["attachments"] as? [String] ?? []

    // 이미 진행 중이면 거절(중복 present 방지).
    if pendingResult != nil {
      result("failed")
      return
    }

    let vc = MFMessageComposeViewController()
    vc.messageComposeDelegate = self
    if !recipients.isEmpty { vc.recipients = recipients }
    if !body.isEmpty { vc.body = body }

    if MFMessageComposeViewController.canSendAttachments() {
      for path in attachments {
        let url = URL(fileURLWithPath: path)
        if let data = try? Data(contentsOf: url) {
          let (uti, filename) = Self.typeInfo(for: path)
          vc.addAttachmentData(data, typeIdentifier: uti, filename: filename)
        }
      }
    }

    guard let presenter = Self.topViewController() else {
      result("failed")
      return
    }
    pendingResult = result
    presenter.present(vc, animated: true, completion: nil)
  }

  func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                    didFinishWith result: MessageComposeResult) {
    controller.dismiss(animated: true, completion: nil)
    // 전송/취소 무관하게 작성창을 열었으므로 성공으로 본다.
    pendingResult?("composed")
    pendingResult = nil
  }

  private static func typeInfo(for path: String) -> (String, String) {
    let lower = path.lowercased()
    let name = (path as NSString).lastPathComponent
    if lower.hasSuffix(".pdf") {
      return ("com.adobe.pdf", name)
    }
    if lower.hasSuffix(".png") {
      return ("public.png", name)
    }
    return ("public.jpeg", name)
  }

  /// SceneDelegate 환경에서 최상단 표시 VC 를 찾는다.
  private static func topViewController() -> UIViewController? {
    var root: UIViewController?
    for scene in UIApplication.shared.connectedScenes {
      if let ws = scene as? UIWindowScene {
        for w in ws.windows where w.isKeyWindow {
          root = w.rootViewController
          break
        }
        if root == nil, let w = ws.windows.first {
          root = w.rootViewController
        }
      }
      if root != nil { break }
    }
    var top = root
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
