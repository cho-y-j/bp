import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/call_log.dart';
import '../../core/env.dart';
import '../../core/sms_composer.dart';
import '../../l10n/l10n_ext.dart';

/// 백엔드 base(/api) → 웹 오리진 추정(공개 링크용).
String webOrigin() => Env.baseUrl.replaceFirst('/api', '');

/// 확인서 서명 링크(외부 공개 페이지).
String confirmationUrl(String shareToken) => '${webOrigin()}/c/$shareToken';

/// 자유 텍스트에서 전화번호로 볼 수 있는 숫자열을 추출(하이픈/공백 제거).
/// 숫자 8자리 미만이면 null(사람 이름 등).
String? extractPhone(String? raw) {
  if (raw == null) return null;
  final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  final onlyNum = digits.replaceAll('+', '');
  if (onlyNum.length < 8) return null;
  return digits;
}

/// 문자 작성창을 열고 결과를 스낵바로 안내한다.
Future<void> composeSms(
  BuildContext context,
  WidgetRef ref, {
  required List<String> recipients,
  required String body,
  List<String> attachments = const [],
}) async {
  final l = context.l;
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final origin =
      box != null ? box.localToGlobal(Offset.zero) & box.size : null;
  final composer = ref.read(smsComposerProvider);
  final result = await composer.compose(
    recipients: recipients.where((r) => r.trim().isNotEmpty).toList(),
    body: body,
    attachments: attachments,
    sharePositionOrigin: origin,
  );
  if (!context.mounted) return;
  switch (result) {
    case SmsResult.composed:
      break; // 작성창을 열었으면 안내 불필요.
    case SmsResult.smsSchemeFallback:
    case SmsResult.sharedFallback:
      messenger.showSnackBar(SnackBar(content: Text(l.smsSharedInstead)));
      break;
    case SmsResult.failed:
      messenger.showSnackBar(SnackBar(content: Text(l.smsFailed)));
      break;
  }
}

/// tel: 로 전화 걸기 + 통화 기록(상대·시각). 시뮬레이터는 다이얼 불가하나 기록은 남는다.
Future<void> launchCallAndRecord(
  BuildContext context,
  WidgetRef ref, {
  required String name,
  required String phone,
}) async {
  final l = context.l;
  final messenger = ScaffoldMessenger.of(context);
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  // 앱에서 건 전화로 기록(권한 불필요) → 복귀 시 제안 카드 판단에 사용.
  await ref.read(callLogControllerProvider.notifier).recordCall(
        name: name,
        phone: digits,
      );
  final uri = Uri(scheme: 'tel', path: digits);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.callFailed)));
    }
  } catch (_) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.callFailed)));
    }
  }
}
