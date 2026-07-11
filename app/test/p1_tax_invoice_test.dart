import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/format.dart';
import 'package:workon/models/models.dart';
import 'package:workon/features/tax/tax_invoice_text.dart';

void main() {
  group('세금계산서 복사 텍스트 — taxInvoiceCopyText', () {
    final supplier = TaxInvoiceSupplier(
        '김기사', '123-45-67890', '기사공영', '서울시 강남구');
    final group = TaxInvoiceGroup(
      buyerName: '대성건설',
      buyerBizNumber: '111-22-33333',
      buyerRegistered: true,
      writeDate: '2026-07-11',
      supplyTotal: 270000,
      taxTotal: 27000,
      grandTotal: 297000,
      items: [
        TaxInvoiceItem('l1', '2026-07-03', '토목 1.5공수', 270000),
      ],
      ledgerIds: ['l1'],
    );

    test('공급자/공급받는자/금액/품목이 텍스트에 포함', () {
      final t = taxInvoiceCopyText(supplier, group);
      expect(t, contains('공급자'));
      expect(t, contains('기사공영'));
      expect(t, contains('123-45-67890'));
      expect(t, contains('대성건설'));
      expect(t, contains('111-22-33333'));
      expect(t, contains('공급가액: 270,000원'));
      expect(t, contains('세액(10%): 27,000원'));
      expect(t, contains('합계금액: 297,000원'));
      expect(t, contains('2026-07-03'));
      expect(t, contains('토목 1.5공수'));
    });

    test('미등록 상대는 "확인 필요" 표기', () {
      final g2 = TaxInvoiceGroup(
        buyerName: '수기상대',
        buyerBizNumber: null,
        buyerRegistered: false,
        writeDate: '2026-07-11',
        supplyTotal: 100000,
        taxTotal: 10000,
        grandTotal: 110000,
        items: const [],
        ledgerIds: const [],
      );
      final t = taxInvoiceCopyText(supplier, g2);
      expect(t, contains('(미등록)'));
      expect(t, contains('※ 확인 필요'));
    });
  });

  group('공급자 등록 여부 — Profile.supplierReady', () {
    Profile p(String? biz) => Profile.fromJson({
          'id': 'u1',
          'phone': '010',
          'bizNumber': biz,
        });
    test('bizNumber 있으면 준비 완료', () {
      expect(p('123-45-67890').supplierReady, isTrue);
    });
    test('bizNumber 없으면 미준비', () {
      expect(p(null).supplierReady, isFalse);
      expect(p('').supplierReady, isFalse);
    });
  });

  group('월 요약 — LedgerSummary.totalGongsu 파싱 + daysWithGongsu', () {
    test('totalGongsu 파싱', () {
      final s = LedgerSummary.fromJson({
        'month': '2026-07',
        'daysWorked': 18,
        'totalGongsu': 19.5,
      });
      expect(s.totalGongsu, 19.5);
      expect(s.daysWorked, 18);
    });

    test('daysWithGongsu 라벨', () {
      expect(daysWithGongsu(18, 19.5), '18일 · 19.5공수');
      expect(daysWithGongsu(18, 20), '18일 · 20공수');
      expect(daysWithGongsu(18, 0), '18일'); // 공수 0 이면 일수만
    });
  });
}
