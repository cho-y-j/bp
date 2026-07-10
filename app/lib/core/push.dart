import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications.dart';

/// FCM 초기화 + 디바이스 토큰 등록 구조.
///
/// **Firebase 설정 파일(GoogleService-Info.plist / google-services.json)이 없으면
/// 초기화가 실패(예외)하는데, 이를 잡아 조용히 skip 하고 앱은 정상 동작한다.**
/// (키 미보유 상태 — 운영 배포 시 설정 파일 + firebase_options 주입.)
class PushService {
  bool _initialized = false;

  Future<void> initAndRegister(WidgetRef ref) async {
    if (_initialized) return;
    _initialized = true;
    try {
      // 설정 파일이 없으면 여기서 예외 → catch 로 skip.
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      await ref
          .read(notificationsRepoProvider)
          .registerDeviceToken(token, platform);
      debugPrint('[Push] device token 등록 완료 ($platform)');
    } catch (e) {
      // Firebase 미설정/권한 거부 등 — 앱 기능에 영향 없이 skip.
      debugPrint('[Push] FCM 초기화 skip (설정 없음): $e');
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService());
