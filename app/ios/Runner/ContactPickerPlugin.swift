import Flutter
import UIKit
import ContactsUI

/// 기기 연락처 시스템 피커 브릿지(iOS).
/// CNContactPickerViewController 는 out-of-process 라 연락처 권한(NSContactsUsageDescription)이
/// 불필요하다. 사용자가 고른 1건의 이름/전화만 앱으로 돌아온다.
class ContactPickerPlugin: NSObject, CNContactPickerDelegate {
  static let channelName = "kr.workon/contacts"

  private var pendingResult: FlutterResult?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let instance = ContactPickerPlugin()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickContact":
      pickContact(result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickContact(_ result: @escaping FlutterResult) {
    // 이미 진행 중이면 거절(중복 present 방지).
    if pendingResult != nil {
      result(nil)
      return
    }
    guard let presenter = Self.topViewController() else {
      result(nil)
      return
    }
    let picker = CNContactPickerViewController()
    picker.delegate = self
    // 전화번호가 있는 연락처 위주로 노출.
    picker.predicateForEnablingContact = NSPredicate(
      format: "phoneNumbers.@count > 0")
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
    pendingResult = result
    presenter.present(picker, animated: true, completion: nil)
  }

  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    let name = [contact.givenName, contact.familyName]
      .filter { !$0.isEmpty }
      .joined(separator: " ")
    let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
    finish(["name": name, "phone": phone])
  }

  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    finish(nil)
  }

  /// FlutterResult 를 한 번만 호출(중복 방지).
  private func finish(_ value: Any?) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    result(value)
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
