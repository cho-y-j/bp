import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/format.dart';
import 'package:workon/widgets/common.dart';

void main() {
  group('금액 표시', () {
    test('천단위 콤마', () {
      expect(formatWon(1234500), '1,234,500');
      expect(formatWonUnit(550000), '550,000 원');
    });
  });

  group('D-day', () {
    test('ddayLabel', () {
      expect(ddayLabel(3), 'D-3');
      expect(ddayLabel(0), 'D-day');
      expect(ddayLabel(-6), 'D+6');
      expect(ddayLabel(null), '');
    });

    test('ddayText (상태별)', () {
      expect(ddayText(3, 'PENDING'), '수금 D-3');
      expect(ddayText(-6, 'OVERDUE'), '기한 지남');
      expect(ddayText(null, 'PAID'), '입금완료');
    });
  });

  group('월/날짜 파라미터', () {
    test('monthParam / dateParam', () {
      expect(monthParam(DateTime(2026, 7, 1)), '2026-07');
      expect(dateParam(DateTime(2026, 7, 3)), '2026-07-03');
    });
    test('요일 계산', () {
      // 2026-07-11 은 토요일
      expect(formatShortDate(DateTime(2026, 7, 11)), '07.11 (토)');
    });
  });
}
