package kr.workon.workon

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth(BiometricPrompt) 는 호스트가 FragmentActivity 여야 하므로
// FlutterActivity 대신 FlutterFragmentActivity 를 사용한다.
class MainActivity : FlutterFragmentActivity() {
  private var contacts: ContactPickerPlugin? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // 문자 작성창 브릿지(kr.workon/sms) 등록.
    val sms = SmsComposerPlugin(this)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SmsComposerPlugin.CHANNEL)
      .setMethodCallHandler { call, result -> sms.handle(call, result) }
    // 기기 연락처 시스템 피커 브릿지(kr.workon/contacts) 등록.
    val picker = ContactPickerPlugin(this)
    contacts = picker
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ContactPickerPlugin.CHANNEL)
      .setMethodCallHandler { call, result -> picker.handle(call, result) }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    // 연락처 피커 결과를 플러그인에 위임. 처리 안 되면 기본 동작.
    if (contacts?.onActivityResult(requestCode, resultCode, data) == true) return
    super.onActivityResult(requestCode, resultCode, data)
  }
}
