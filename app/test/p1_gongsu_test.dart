import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/amount_calc.dart';

void main() {
  group('공수(GONGSU) 수량 검증 — validateGongsuQuantity', () {
    test('0.5/1/1.5 등 0.1 단위는 유효', () {
      expect(validateGongsuQuantity(0.5), 0.5);
      expect(validateGongsuQuantity(1), 1.0);
      expect(validateGongsuQuantity(1.5), 1.5);
      expect(validateGongsuQuantity(2.3), 2.3);
      expect(validateGongsuQuantity(5.0), 5.0);
    });

    test('0 이하는 무효', () {
      expect(validateGongsuQuantity(0), isNull);
      expect(validateGongsuQuantity(-1), isNull);
    });

    test('0.1 단위가 아니면 무효 (0.05/0.25/1.55)', () {
      expect(validateGongsuQuantity(0.05), isNull);
      expect(validateGongsuQuantity(0.25), isNull);
      expect(validateGongsuQuantity(1.55), isNull);
    });

    test('부동소수 오차(0.1*3) 보정', () {
      expect(validateGongsuQuantity(0.1 + 0.1 + 0.1), 0.3);
    });
  });

  group('공수 금액 계산 — calcAmount(GONGSU)', () {
    test('1.5공수 × 180,000 = 270,000, unit=공수', () {
      final r = calcAmount(rateType: 'GONGSU', rate: 180000, quantity: 1.5);
      expect(r.total, 270000);
      expect(r.subtotal, 270000);
      final base = r.items.first;
      expect(base.unit, '공수');
      expect(base.quantity, 1.5);
      expect(base.rate, 180000);
      expect(base.amount, 270000);
    });

    test('일당(DAILY)은 unit 없음', () {
      final r = calcAmount(rateType: 'DAILY', rate: 150000, quantity: 2);
      expect(r.items.first.unit, isNull);
      expect(r.total, 300000);
    });

    test('공수 라벨은 기본(공수)', () {
      final r = calcAmount(rateType: 'GONGSU', rate: 100000, quantity: 0.5);
      expect(r.items.first.label, '기본(공수)');
      expect(r.total, 50000);
    });
  });

  group('수량+단위 포맷 — formatQtyUnit', () {
    test('공수는 "1.5공수", 정수는 "2공수"', () {
      expect(formatQtyUnit(1.5, '공수'), '1.5공수');
      expect(formatQtyUnit(2, '공수'), '2공수');
    });
    test('단위 없으면 수량만', () {
      expect(formatQtyUnit(3, null), '3');
      expect(formatQtyUnit(1.5, null), '1.5');
    });
  });
}
