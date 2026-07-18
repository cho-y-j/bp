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
    // 문자 작성창(MFMessageComposeViewController) 브릿지 등록.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SmsComposerPlugin") {
      SmsComposerPlugin.register(with: registrar.messenger())
    }
    // 기기 연락처 시스템 피커(CNContactPickerViewController) 브릿지 등록.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ContactPickerPlugin") {
      ContactPickerPlugin.register(with: registrar.messenger())
    }
  }
}
