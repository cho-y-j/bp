package kr.workon.workon

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth(BiometricPrompt) 는 호스트가 FragmentActivity 여야 하므로
// FlutterActivity 대신 FlutterFragmentActivity 를 사용한다.
class MainActivity : FlutterFragmentActivity()
