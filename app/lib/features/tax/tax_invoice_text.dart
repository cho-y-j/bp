import '../../core/format.dart';
import '../../models/models.dart';

/// 세금계산서 상대별 그룹을 홈택스 입력용 "복사하기 좋은" 텍스트로 포맷.
/// 순수 함수(단위 테스트 대상). 서버 `text` 와 동일 취지의 클라이언트 포맷.
String taxInvoiceCopyText(TaxInvoiceSupplier supplier, TaxInvoiceGroup g) {
  final b = StringBuffer();
  b.writeln('■ 공급자(나)');
  b.writeln('- 상호: ${supplier.bizName ?? '(미등록)'}');
  b.writeln('- 사업자번호: ${supplier.bizNumber ?? '(미등록)'}');
  if ((supplier.name ?? '').isNotEmpty) b.writeln('- 성명: ${supplier.name}');
  if ((supplier.bizAddress ?? '').isNotEmpty) {
    b.writeln('- 주소: ${supplier.bizAddress}');
  }
  b.writeln('');
  b.writeln('■ 공급받는자: ${g.buyerName}');
  b.writeln(
      '- 사업자번호: ${g.buyerBizNumber ?? '(미등록)'}${g.buyerRegistered ? '' : ' ※ 확인 필요'}');
  b.writeln('- 작성일자: ${g.writeDate}');
  b.writeln('- 공급가액: ${formatWon(g.supplyTotal)}원');
  b.writeln('- 세액(10%): ${formatWon(g.taxTotal)}원');
  b.writeln('- 합계금액: ${formatWon(g.grandTotal)}원');
  b.writeln('- 품목');
  for (final it in g.items) {
    b.writeln('  · ${it.date}  ${it.content}  ${formatWon(it.supplyAmount)}원');
  }
  return b.toString().trimRight();
}
