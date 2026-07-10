import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/amount_calc.dart';

void main() {
  group('calcAmount (backend amount.util.ts 미러)', () {
    test('일당 550,000 × 1일 = 550,000', () {
      final r = calcAmount(rateType: 'DAILY', rate: 550000, quantity: 1);
      expect(r.subtotal, 550000);
      expect(r.total, 550000);
      expect(r.items.length, 1);
      expect(r.items.first.label, '기본(일당)');
    });

    test('시급 80,000 × 8시간 = 640,000', () {
      final r = calcAmount(rateType: 'HOURLY', rate: 80000, quantity: 8);
      expect(r.total, 640000);
    });

    test('연장 항목 합산: 550,000 + (60,000 × 1.5) = 640,000', () {
      final r = calcAmount(
        rateType: 'DAILY',
        rate: 550000,
        quantity: 1,
        additionalItems: const [
          AdditionalItemInput(type: 'OVERTIME', rate: 60000, quantity: 1.5),
        ],
      );
      expect(r.items.length, 2);
      expect(r.items[1].amount, 90000);
      expect(r.total, 640000);
    });

    test('부가세 10% 적용', () {
      final r = calcAmount(rateType: 'DAILY', rate: 1000000, quantity: 1, vatRate: 0.1);
      expect(r.vat, 100000);
      expect(r.total, 1100000);
    });

    test('음수 단가는 0 으로 방어', () {
      final r = calcAmount(rateType: 'DAILY', rate: -100, quantity: 3);
      expect(r.total, 0);
    });

    test('OTHER 라벨 커스텀', () {
      final r = calcAmount(
        rateType: 'PER_CASE',
        rate: 0,
        quantity: 0,
        additionalItems: const [
          AdditionalItemInput(type: 'OTHER', label: '유류비', rate: 30000, quantity: 1),
        ],
      );
      expect(r.items[1].label, '유류비');
      expect(r.total, 30000);
    });
  });
}
