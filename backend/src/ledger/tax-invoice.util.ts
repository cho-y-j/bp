/**
 * 세금계산서 1단계(홈택스 입력용) 데이터 정리 — 순수 함수(단위 테스트 대상).
 *
 * 설계:
 *  - 상대(공급받는자)별로 SIGNED 확인서를 묶어 공급가액 합계·세액(10%)·품목을 정리한다.
 *  - 세액은 공급가액의 10% 반올림(정수 원). 공급가액은 확인서 amountCalc.subtotal(부가세 전 공급가).
 *  - 발행 표시된(taxInvoicedAt) 항목은 호출부에서 이미 제외하고 넘긴다.
 */

/** 공급가액 → 세액(10%, 정수 원 반올림). */
export function computeTax(supplyAmount: number): number {
  if (!Number.isFinite(supplyAmount) || supplyAmount <= 0) return 0;
  return Math.round(supplyAmount * 0.1);
}

export interface TaxInvoiceSourceRow {
  ledgerId: string;
  businessId: string | null;
  buyerName: string; // 공급받는자 상호(연동 사업장명 or 수기명)
  buyerBizNumber: string | null; // 공급받는자 사업자번호(연동 사업장만)
  date: string; // 작업 일자 YYYY-MM-DD
  content: string; // 품목/내용
  supplyAmount: number; // 공급가액(원)
}

export interface TaxInvoiceItem {
  ledgerId: string;
  date: string;
  content: string;
  supplyAmount: number;
}

export interface TaxInvoiceGroup {
  buyerName: string;
  buyerBizNumber: string | null;
  buyerRegistered: boolean; // 연동 사업장 + 사업자번호 보유(홈택스 상대 등록 가능)
  writeDate: string; // 작성일자
  items: TaxInvoiceItem[];
  supplyTotal: number; // 공급가액 합계
  taxTotal: number; // 세액(10%)
  grandTotal: number; // 합계금액(공급가+세액)
  ledgerIds: string[]; // 발행 표시(mark) 대상 id
}

export interface TaxInvoiceSupplier {
  name: string | null; // 성명(대표자)
  bizNumber: string | null; // 사업자번호
  bizName: string | null; // 상호
  bizAddress: string | null; // 사업장 주소
}

/** 소스 행들을 상대(공급받는자)별로 묶어 세금계산서 그룹으로 집계. */
export function buildTaxInvoiceGroups(
  rows: TaxInvoiceSourceRow[],
  writeDate: string,
): TaxInvoiceGroup[] {
  const map = new Map<string, TaxInvoiceGroup>();
  for (const r of rows) {
    const key = r.businessId ? `biz:${r.businessId}` : `manual:${r.buyerName}`;
    let g = map.get(key);
    if (!g) {
      g = {
        buyerName: r.buyerName,
        buyerBizNumber: r.buyerBizNumber,
        buyerRegistered: !!(r.businessId && r.buyerBizNumber),
        writeDate,
        items: [],
        supplyTotal: 0,
        taxTotal: 0,
        grandTotal: 0,
        ledgerIds: [],
      };
      map.set(key, g);
    }
    g.items.push({
      ledgerId: r.ledgerId,
      date: r.date,
      content: r.content,
      supplyAmount: r.supplyAmount,
    });
    g.ledgerIds.push(r.ledgerId);
    g.supplyTotal += r.supplyAmount;
  }
  const groups = [...map.values()];
  for (const g of groups) {
    g.taxTotal = computeTax(g.supplyTotal);
    g.grandTotal = g.supplyTotal + g.taxTotal;
    g.items.sort((a, b) => a.date.localeCompare(b.date));
  }
  // 공급가액 큰 상대부터
  groups.sort((a, b) => b.supplyTotal - a.supplyTotal);
  return groups;
}

const won = (n: number): string => `${Math.round(n).toLocaleString('ko-KR')}원`;

/** 홈택스 입력용 "복사하기 좋은" 텍스트 포맷. */
export function formatTaxInvoiceText(
  supplier: TaxInvoiceSupplier,
  groups: TaxInvoiceGroup[],
): string {
  const lines: string[] = [];
  lines.push('■ 공급자(나)');
  lines.push(`- 상호: ${supplier.bizName ?? '(미등록)'}`);
  lines.push(`- 사업자번호: ${supplier.bizNumber ?? '(미등록)'}`);
  lines.push(`- 성명: ${supplier.name ?? '(미등록)'}`);
  if (supplier.bizAddress) lines.push(`- 주소: ${supplier.bizAddress}`);
  lines.push('');

  if (groups.length === 0) {
    lines.push('발행 대상(서명 완료·미발행) 확인서가 없습니다.');
    return lines.join('\n');
  }

  groups.forEach((g, idx) => {
    lines.push(`━━━ ${idx + 1}. 공급받는자: ${g.buyerName} ━━━`);
    lines.push(
      `- 사업자번호: ${g.buyerBizNumber ?? '(미등록)'}${
        g.buyerRegistered ? '' : ' ※ 확인 필요'
      }`,
    );
    lines.push(`- 작성일자: ${g.writeDate}`);
    lines.push(`- 공급가액: ${won(g.supplyTotal)}`);
    lines.push(`- 세액(10%): ${won(g.taxTotal)}`);
    lines.push(`- 합계금액: ${won(g.grandTotal)}`);
    lines.push('- 품목');
    for (const it of g.items) {
      lines.push(`  · ${it.date}  ${it.content}  ${won(it.supplyAmount)}`);
    }
    lines.push('');
  });
  return lines.join('\n').trimEnd();
}
