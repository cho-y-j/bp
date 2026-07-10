import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/mask_geometry.dart';
import 'package:workon/core/signature.dart';
import 'package:workon/core/format.dart';

void main() {
  group('마스킹 좌표 변환 (normalizeDragRect)', () {
    const display = Size(200, 400);

    test('정방향 드래그 → 정규화 0~1 좌표', () {
      final r = normalizeDragRect(
          const Offset(20, 40), const Offset(120, 240), display);
      expect(r.x, closeTo(0.1, 1e-9)); // 20/200
      expect(r.y, closeTo(0.1, 1e-9)); // 40/400
      expect(r.width, closeTo(0.5, 1e-9)); // (120-20)/200
      expect(r.height, closeTo(0.5, 1e-9)); // (240-40)/400
      expect(r.page, 0);
      expect(r.isValid, isTrue);
    });

    test('역방향 드래그(끝→시작)도 동일한 사각형', () {
      final forward = normalizeDragRect(
          const Offset(20, 40), const Offset(120, 240), display);
      final backward = normalizeDragRect(
          const Offset(120, 240), const Offset(20, 40), display);
      expect(backward.x, closeTo(forward.x, 1e-9));
      expect(backward.y, closeTo(forward.y, 1e-9));
      expect(backward.width, closeTo(forward.width, 1e-9));
      expect(backward.height, closeTo(forward.height, 1e-9));
    });

    test('캔버스 밖으로 나간 좌표는 0~1 로 clamp', () {
      final r = normalizeDragRect(
          const Offset(-50, -100), const Offset(400, 800), display);
      expect(r.x, 0.0);
      expect(r.y, 0.0);
      expect(r.width, 1.0);
      expect(r.height, 1.0);
    });

    test('toJson 은 백엔드 MaskRegionDto 필드와 일치', () {
      final r = normalizeDragRect(
          const Offset(50, 100), const Offset(150, 300), display);
      final j = r.toJson();
      expect(j.keys.toSet(), {'page', 'x', 'y', 'width', 'height'});
      expect(j['page'], 0);
    });

    test('regionToDisplayRect 는 normalize 의 역변환', () {
      final r = normalizeDragRect(
          const Offset(50, 100), const Offset(150, 300), display);
      final rect = regionToDisplayRect(r, display);
      expect(rect.left, closeTo(50, 1e-6));
      expect(rect.top, closeTo(100, 1e-6));
      expect(rect.width, closeTo(100, 1e-6));
      expect(rect.height, closeTo(200, 1e-6));
    });
  });

  group('알림 뱃지 카운트', () {
    test('0 이하는 빈 문자열(숨김)', () {
      expect(badgeCount(0), '');
      expect(badgeCount(-3), '');
    });
    test('1~9 는 그대로', () {
      expect(badgeCount(1), '1');
      expect(badgeCount(9), '9');
    });
    test('9 초과는 9+', () {
      expect(badgeCount(10), '9+');
      expect(badgeCount(128), '9+');
    });
  });

  group('서명 PNG 인코딩', () {
    testWidgets('획 → 투명 PNG 바이트 (PNG 시그니처)', (tester) async {
      await tester.runAsync(() async {
        final strokes = [
          [const Offset(10, 20), const Offset(40, 60), const Offset(80, 40)],
          [const Offset(100, 100)], // 단일 점
        ];
        final png = await encodeSignaturePng(strokes, const Size(200, 120));
        expect(png.length, greaterThan(8));
        // PNG 매직 넘버: 89 50 4E 47 0D 0A 1A 0A
        expect(png.sublist(0, 8),
            [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      });
    });

    testWidgets('data URI 형식 + ≤1MB', (tester) async {
      await tester.runAsync(() async {
        final strokes = [
          [const Offset(10, 20), const Offset(180, 100)],
        ];
        final uri = await encodeSignatureDataUri(strokes, const Size(320, 180));
        expect(uri.startsWith('data:image/png;base64,'), isTrue);
        expect(uri.length, lessThanOrEqualTo(1024 * 1024));
      });
    });

    testWidgets('빈 서명도 유효한 PNG(투명) 를 만든다', (tester) async {
      await tester.runAsync(() async {
        final png = await encodeSignaturePng([], const Size(100, 60));
        expect(png.sublist(0, 8),
            [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      });
    });
  });
}
