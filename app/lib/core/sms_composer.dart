import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 문자 작성창 호출 결과.
enum SmsResult {
  /// 네이티브 작성창을 열었다(사용자 전송/취소는 앱이 관여 안 함).
  composed,

  /// 문자 불가 기기 → 시스템 공유 시트로 폴백했다.
  sharedFallback,

  /// 문자 불가 기기 → `sms:` 스킴(텍스트만)으로 폴백했다.
  smsSchemeFallback,

  /// 어떤 경로로도 열지 못했다.
  failed,
}

/// 문자 작성창(수신인·본문·이미지 첨부)을 여는 브릿지.
///  - iOS: MFMessageComposeViewController (recipients/body/attachments).
///  - Android: ACTION_SENDTO(smsto:) 텍스트 / ACTION_SEND(image/*)+FileProvider 이미지.
///  - 문자 불가 기기: 시스템 공유 시트 또는 `sms:` 스킴 폴백.
abstract class SmsComposer {
  /// 텍스트 문자 작성창을 열 수 있는 기기인가.
  Future<bool> canSendText();

  /// 이미지 첨부 문자를 보낼 수 있는 기기인가.
  Future<bool> canSendAttachments();

  /// 작성창을 연다. [attachments] 는 첨부할 로컬 파일 경로들.
  Future<SmsResult> compose({
    required List<String> recipients,
    required String body,
    List<String> attachments = const [],
    Rect? sharePositionOrigin,
  });
}

/// 실제 네이티브 브릿지 구현 + 폴백.
class PlatformSmsComposer implements SmsComposer {
  static const MethodChannel _channel = MethodChannel('kr.workon/sms');

  const PlatformSmsComposer();

  @override
  Future<bool> canSendText() async {
    try {
      final ok = await _channel.invokeMethod<bool>('canSendText');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> canSendAttachments() async {
    try {
      final ok = await _channel.invokeMethod<bool>('canSendAttachments');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SmsResult> compose({
    required List<String> recipients,
    required String body,
    List<String> attachments = const [],
    Rect? sharePositionOrigin,
  }) async {
    try {
      final res = await _channel.invokeMethod<String>('compose', {
        'recipients': recipients,
        'body': body,
        'attachments': attachments,
      });
      // 네이티브가 작성창(또는 자체 공유 폴백)을 열었으면 성공.
      if (res == 'composed' || res == 'shared') {
        return SmsResult.composed;
      }
      // 'unsupported' 등 → Dart 폴백으로.
    } on MissingPluginException {
      // 채널 미등록(테스트/미지원 플랫폼) → 폴백.
    } catch (e) {
      if (kDebugMode) debugPrint('[SmsComposer] compose error: $e');
    }
    return _fallback(
      recipients: recipients,
      body: body,
      attachments: attachments,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// 문자 불가 기기 폴백:
  ///  - 이미지 첨부가 있으면 시스템 공유 시트(Messages 포함)로.
  ///  - 텍스트만이면 `sms:` 스킴으로 문자 앱을 연다.
  Future<SmsResult> _fallback({
    required List<String> recipients,
    required String body,
    required List<String> attachments,
    Rect? sharePositionOrigin,
  }) async {
    if (attachments.isNotEmpty) {
      try {
        await Share.shareXFiles(
          attachments.map((p) => XFile(p)).toList(),
          text: body,
          sharePositionOrigin: sharePositionOrigin,
        );
        return SmsResult.sharedFallback;
      } catch (e) {
        if (kDebugMode) debugPrint('[SmsComposer] share fallback error: $e');
      }
    }
    // 텍스트만 → sms: 스킴.
    final to = recipients.join(',');
    final uri = Uri(
      scheme: 'sms',
      path: to,
      queryParameters: body.isEmpty ? null : {'body': body},
    );
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return SmsResult.smsSchemeFallback;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SmsComposer] sms: fallback error: $e');
    }
    // 최후: 공유 시트(텍스트).
    try {
      await Share.share(body, sharePositionOrigin: sharePositionOrigin);
      return SmsResult.sharedFallback;
    } catch (_) {
      return SmsResult.failed;
    }
  }
}

/// 화면에서 주입받는 문자 작성기. 테스트에서 가짜 구현으로 override.
final smsComposerProvider =
    Provider<SmsComposer>((ref) => const PlatformSmsComposer());
