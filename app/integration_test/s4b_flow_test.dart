import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workon/main.dart';
import 'package:workon/core/file_pick.dart';

/// 통합 테스트용 가짜 파일 선택 소스 — 네이티브 피커 대신 합성 신분증 이미지 반환.
class _FakePickSource implements FilePickSource {
  @override
  Future<PickedDoc?> pickImage({required bool fromCamera}) => _card();
  @override
  Future<PickedDoc?> pickPdf() => _card();

  Future<PickedDoc> _card() async {
    const size = Size(600, 380);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFEFEADF));
    void text(String s, double x, double y, double fs, Color col) {
      final tp = TextPainter(
          text: TextSpan(
              text: s,
              style: TextStyle(
                  color: col, fontSize: fs, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(x, y));
    }

    text('주민등록증', 30, 22, 30, const Color(0xFF222222));
    text('홍 길 동', 30, 92, 40, const Color(0xFF111111));
    text('900101-1234567', 30, 168, 30, const Color(0xFF333333));
    text('서울특별시 강남구 테헤란로 123', 30, 230, 22, const Color(0xFF444444));
    final pic = recorder.endRecording();
    final img = await pic.toImage(600, 380);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return PickedDoc(
        bytes: bd!.buffer.asUint8List(), filename: 'id.png', mime: 'image/png');
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  bool converted = false;

  Future<void> shot(WidgetTester tester, String name) async {
    if (!converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
    }
    await tester.pump(const Duration(milliseconds: 300));
    await binding.takeScreenshot(name);
  }

  Future<bool> pumpUntil(WidgetTester tester, Finder finder,
      {Duration timeout = const Duration(seconds: 12)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> tapIf(WidgetTester tester, Finder f) async {
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f.first);
      await tester.pump(const Duration(milliseconds: 600));
    }
  }

  // 더보기 탭으로 전환. 스택 깊이가 불명확할 수 있어 셸(탭바)까지 pop 후 menu 탭 선택.
  Future<void> goMoreTab(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      if (find.text('서류 지갑').evaluate().isNotEmpty) return;
      final tab = find.byIcon(Icons.menu_rounded);
      if (tab.evaluate().isNotEmpty) {
        await tester.tap(tab.first);
        await tester.pump(const Duration(milliseconds: 500));
        if (find.text('서류 지갑').evaluate().isNotEmpty) return;
      }
      try {
        await tester.pageBack();
      } catch (_) {}
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> back(WidgetTester tester) async {
    try {
      await tester.pageBack();
    } catch (_) {}
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('S4b 지갑·사업장·알림 E2E (실 백엔드)', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        filePickSourceProvider.overrideWithValue(_FakePickSource()),
      ],
      child: const WorkonApp(),
    ));
    await tester.pump(const Duration(seconds: 1));

    // 로그인 (A: 01011112222)
    if (await pumpUntil(tester, find.text('인증번호 받기'),
        timeout: const Duration(seconds: 6))) {
      await tester.enterText(find.byType(TextField).first, '01011112222');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('인증번호 받기'));
      final ready = await pumpUntil(tester, find.text('인증하고 시작하기'));
      expect(ready, isTrue);
      await tester.tap(find.text('인증하고 시작하기'));
    }
    if (await pumpUntil(tester, find.text('시작하기'),
        timeout: const Duration(seconds: 4))) {
      await tester.enterText(find.byType(TextField).first, '김기사');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('시작하기'));
    }

    final home = await pumpUntil(tester, find.text('더보기'),
        timeout: const Duration(seconds: 15));
    expect(home, isTrue, reason: '메인쉘 진입');
    await pumpUntil(tester, find.text('이번 달 요약'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 's4b-01-home'); // 벨 뱃지

    // ---- 알림 목록 + 폭염 ack ----
    await tester.tap(find.byIcon(Icons.notifications_none_rounded).first);
    await pumpUntil(tester, find.text('알림'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 's4b-02-notifications');
    await tapIf(tester, find.text('확인')); // 폭염 알림 ack
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 's4b-03-notifications-acked');
    await back(tester);

    // ---- 받은 작업: 수락 → 시작(컨디션) → 완료 ----
    await goMoreTab(tester);
    await tester.tap(find.text('받은 작업'));
    await pumpUntil(tester, find.text('반포자이 리모델링'),
        timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    await tapIf(tester, find.text('수락'));
    await pumpUntil(tester, find.text('작업 시작'),
        timeout: const Duration(seconds: 8));
    await tester.tap(find.text('작업 시작'));
    // 컨디션 체크 다이얼로그 대기 후 '좋아요'
    await pumpUntil(tester, find.text('컨디션 체크'),
        timeout: const Duration(seconds: 6));
    await tapIf(tester, find.text('좋아요'));
    await pumpUntil(tester, find.text('작업 완료'),
        timeout: const Duration(seconds: 12));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 's4b-04-job-in-progress');
    await tapIf(tester, find.text('작업 완료'));
    await pumpUntil(tester, find.text('완료'),
        timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 2));
    await shot(tester, 's4b-05-job-done');
    await back(tester);

    // ---- 사업장 홈 → 수신함 서명 → 정산 pay ----
    await goMoreTab(tester);
    if (find.text('사업장 홈').evaluate().isNotEmpty) {
      await tester.tap(find.text('사업장 홈'));
    } else {
      await tapIf(tester, find.text('사업장 모드'));
    }
    await pumpUntil(tester, find.text('수신함'),
        timeout: const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 's4b-06-biz-home');

    await tester.tap(find.text('수신함'));
    await pumpUntil(tester, find.text('판교 오피스 신축'),
        timeout: const Duration(seconds: 10));
    await tester.tap(find.text('판교 오피스 신축'));
    // 상세 로드 대기(SingleChildScrollView 로 서명 버튼도 즉시 빌드됨).
    final signReady = await pumpUntil(tester, find.text('서명하고 확정'),
        timeout: const Duration(seconds: 10));
    if (signReady) {
      // 서명 영역을 뷰포트로(프로그램 스크롤 — 제스처 충돌 없음).
      await tester.ensureVisible(find.text('서명하고 확정'));
      await tester.pump(const Duration(milliseconds: 500));
      // 서명 패드에 두 획 그리기(패드 힌트 중심 기준).
      final hint = find.textContaining('서명하세요');
      if (hint.evaluate().isNotEmpty) {
        final p = tester.getCenter(hint.first);
        await tester.dragFrom(p - const Offset(70, 0), const Offset(90, 24));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.dragFrom(p + const Offset(-20, 24), const Offset(80, -30));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await shot(tester, 's4b-07-signing');
      await tester.tap(find.text('서명하고 확정'));
      await pumpUntil(tester, find.textContaining('서 명 완 료'),
          timeout: const Duration(seconds: 12));
      await tester.pump(const Duration(seconds: 1));
      await shot(tester, 's4b-08-signed');
      await back(tester); // 상세 → 수신함
    }
    await back(tester); // 수신함 → 사업장 홈

    if (find.text('정산').evaluate().isNotEmpty) {
      await tester.tap(find.text('정산'));
      await pumpUntil(tester, find.textContaining('지급'),
          timeout: const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));
      await shot(tester, 's4b-09-settlement');
      await tapIf(tester, find.textContaining('지급'));
      await tester.pump(const Duration(seconds: 2));
      await shot(tester, 's4b-10-settlement-paid');
      await back(tester);
    }
    await back(tester); // 사업장 홈 → 셸

    // ---- 서류 지갑: 업로드 → 마스킹 → 묶음 공유(마지막) ----
    await goMoreTab(tester);
    await tester.tap(find.text('서류 지갑'));
    await pumpUntil(tester, find.text('서류 추가'));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, 's4b-11-wallet');

    await tester.tap(find.text('서류 추가'));
    await pumpUntil(tester, find.text('갤러리에서 선택'));
    await tester.tap(find.text('갤러리에서 선택'));
    final metaReady = await pumpUntil(tester, find.text('업로드'));
    expect(metaReady, isTrue, reason: '업로드 메타 시트');
    await tapIf(tester, find.text('신분증'));
    await tester.tap(find.text('업로드'));
    final maskAsk = await pumpUntil(tester, find.text('마스킹 편집'),
        timeout: const Duration(seconds: 15));
    if (maskAsk) {
      await tester.tap(find.text('마스킹 편집'));
      await pumpUntil(tester, find.text('마스킹본 저장'));
      await tester.pump(const Duration(seconds: 1));
      final img = find.byType(Image);
      if (img.evaluate().isNotEmpty) {
        final center = tester.getCenter(img.first);
        await tester.dragFrom(
            center - const Offset(60, 10), const Offset(120, 40));
        await tester.pump(const Duration(milliseconds: 500));
      }
      await shot(tester, 's4b-12-mask-editor');
      await tester.tap(find.text('마스킹본 저장'));
      await pumpUntil(tester, find.text('서류 추가'),
          timeout: const Duration(seconds: 12));
      await tester.pump(const Duration(seconds: 1));
    }
    await shot(tester, 's4b-13-wallet-with-doc');

    // 묶음 보내기(주요 CTA): 롱프레스 선택 → 링크 생성 → 시스템 공유 시트(마지막)
    final card = find.text('신분증');
    if (card.evaluate().isNotEmpty) {
      await tester.longPress(card.first);
      await tester.pump(const Duration(milliseconds: 600));
      await tapIf(tester, find.textContaining('묶어 보내기'));
      final shareReady = await pumpUntil(tester, find.text('링크 만들고 공유'));
      if (shareReady) {
        await shot(tester, 's4b-14-share-options');
        await tester.tap(find.text('링크 만들고 공유'));
        await tester.pump(const Duration(seconds: 2));
      }
    }
  });
}
