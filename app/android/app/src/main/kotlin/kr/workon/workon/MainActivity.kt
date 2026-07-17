package kr.workon.workon

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth(BiometricPrompt) 는 호스트가 FragmentActivity 여야 하므로
// FlutterActivity 대신 FlutterFragmentActivity 를 사용한다.
class MainActivity : FlutterFragmentActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // 문자 작성창 브릿지(kr.workon/sms) 등록.
    val sms = SmsComposerPlugin(this)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SmsComposerPlugin.CHANNEL)
      .setMethodCallHandler { call, result -> sms.handle(call, result) }
  }
}
