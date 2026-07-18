import { computeOutstanding } from '../ledger/ledger.util';
import { toKstDateStr } from '../confirmations/time.util';

// ============================================================================
//  거래처 목록 파생 계산 (순수 함수 — DB 접근 없음, 단위 테스트 대상)
//   - 확인서(원천) + 장부(미수) + partners 보강행 + 연결 사업장 정보를 병합한다.
//   - 통계(건수·미수·최근 작업일)는 저장하지 않고 매 조회 시 파생한다.
// ============================================================================

/** 확인서 최소 참조(상대·작업일). */
export interface PartnerConfirmationRef {
  businessId: string | null;
  companyName: string;
  manualContact: string | null;
  date: Date;
}

/** 장부 항목 최소 참조(미수 계산용). 파생(derived) 항목은 호출 전에 제외한다. */
export interface PartnerLedgerRef {
  businessId: string | null;
  counterpartyName: string | null;
  amount: number;
  payments: unknown;
  dueDate: Date | null;
}

/** partners 테이블 보강행. */
export interface PartnerRow {
  id: string;
  name: string;
  phone: string | null;
  alias: string | null;
  bizNumber: string | null;
  email: string | null;
  memo: string | null;
}

/** 연결(승격) 사업장 참조 — 이름·소유자 전화(문자/전화용). */
export interface PartnerBusinessRef {
  id: string;
  name: string;
  ownerPhone: string | null;
}

/** GET /partners 응답 1건. */
export interface PartnerListItem {
  /** 수기 거래처 partners 행 id. 연결(승격) 상대는 null. */
  id: string | null;
  /** 연결(승격) 상대면 사업장 id. 수기 상대는 null. */
  businessId: string | null;
  /** 연결(승격) 거래처 여부(배지용). */
  linked: boolean;
  name: string;
  phone: string | null;
  alias: string | null;
  bizNumber: string | null;
  email: string | null;
  memo: string | null;
  /** 확인서 건수(상태 무관). */
  confirmationCount: number;
  /** 미수 잔액(장부 파생, derived 제외). */
  outstanding: number;
  /** 입금 합계. */
  paid: number;
  /** 최근 작업일(KST YYYY-MM-DD). 확인서 없으면 null. */
  lastWorkedDate: string | null;
}

interface ManualStat {
  count: number;
  lastDate: Date | null;
  latestPhone: string | null;
  phoneDate: Date | null; // latestPhone 을 채운 확인서의 작업일(전화 선택 순서 독립성)
}
interface OutstandingAgg {
  outstanding: number;
  paid: number;
}

/**
 * 거래처 목록을 파생 계산한다.
 *  - 수기 상대: 확인서 companyName(=name) 로 그룹. partners 보강행과 name 으로 병합.
 *  - 연결 상대: 확인서 businessId 로 그룹. businesses 이름·소유자 전화로 채움.
 *  - 정렬: 최근 작업일 desc(없으면 뒤), 동률이면 이름.
 */
export function buildPartnerList(input: {
  confirmations: PartnerConfirmationRef[];
  ledgerEntries: PartnerLedgerRef[]; // derived 제외된 상태로 전달
  partnerRows: PartnerRow[];
  businesses: PartnerBusinessRef[];
  now?: Date;
}): PartnerListItem[] {
  const now = input.now ?? new Date();

  // --- 확인서 그룹 통계 (수기: name / 연결: businessId) ---
  const manualStat = new Map<string, ManualStat>();
  const connectedStat = new Map<string, ManualStat>();
  for (const c of input.confirmations) {
    if (c.businessId) {
      const s = connectedStat.get(c.businessId) ?? {
        count: 0,
        lastDate: null,
        latestPhone: null,
        phoneDate: null,
      };
      s.count += 1;
      if (!s.lastDate || c.date.getTime() > s.lastDate.getTime()) {
        s.lastDate = c.date;
      }
      connectedStat.set(c.businessId, s);
    } else {
      const name = c.companyName;
      const s = manualStat.get(name) ?? {
        count: 0,
        lastDate: null,
        latestPhone: null,
        phoneDate: null,
      };
      s.count += 1;
      if (!s.lastDate || c.date.getTime() > s.lastDate.getTime()) {
        s.lastDate = c.date;
      }
      // 대표 전화 = 연락처가 있는 확인서 중 가장 최근 것(순서 독립).
      if (
        c.manualContact &&
        (!s.phoneDate || c.date.getTime() >= s.phoneDate.getTime())
      ) {
        s.latestPhone = c.manualContact;
        s.phoneDate = c.date;
      }
      manualStat.set(name, s);
    }
  }

  // --- 장부 미수 집계 (수기: counterpartyName / 연결: businessId) ---
  const manualOut = new Map<string, OutstandingAgg>();
  const connectedOut = new Map<string, OutstandingAgg>();
  for (const e of input.ledgerEntries) {
    const { paid, outstanding } = computeOutstanding(
      e.amount,
      e.payments,
      e.dueDate,
      now,
    );
    if (e.businessId) {
      const g = connectedOut.get(e.businessId) ?? { outstanding: 0, paid: 0 };
      g.outstanding += outstanding;
      g.paid += paid;
      connectedOut.set(e.businessId, g);
    } else {
      const name = e.counterpartyName ?? '(미지정)';
      const g = manualOut.get(name) ?? { outstanding: 0, paid: 0 };
      g.outstanding += outstanding;
      g.paid += paid;
      manualOut.set(name, g);
    }
  }

  const rowByName = new Map(input.partnerRows.map((r) => [r.name, r]));
  const bizById = new Map(input.businesses.map((b) => [b.id, b]));

  const items: PartnerListItem[] = [];

  // --- 수기 거래처: 확인서 이름 ∪ 보강행 이름 (확인서가 삭제돼도 보강행은 유지) ---
  const manualNames = new Set<string>([
    ...manualStat.keys(),
    ...rowByName.keys(),
  ]);
  for (const name of manualNames) {
    const stat = manualStat.get(name) ?? {
      count: 0,
      lastDate: null,
      latestPhone: null,
      phoneDate: null,
    };
    const out = manualOut.get(name) ?? { outstanding: 0, paid: 0 };
    const row = rowByName.get(name);
    items.push({
      id: row?.id ?? null,
      businessId: null,
      linked: false,
      name,
      phone: stat.latestPhone ?? row?.phone ?? null,
      alias: row?.alias ?? null,
      bizNumber: row?.bizNumber ?? null,
      email: row?.email ?? null,
      memo: row?.memo ?? null,
      confirmationCount: stat.count,
      outstanding: out.outstanding,
      paid: out.paid,
      lastWorkedDate: stat.lastDate ? toKstDateStr(stat.lastDate) : null,
    });
  }

  // --- 연결(승격) 거래처: 확인서 businessId 그룹 ---
  for (const [businessId, stat] of connectedStat) {
    const biz = bizById.get(businessId);
    const out = connectedOut.get(businessId) ?? { outstanding: 0, paid: 0 };
    items.push({
      id: null,
      businessId,
      linked: true,
      name: biz?.name ?? '(사업장)',
      phone: biz?.ownerPhone ?? null,
      alias: null,
      bizNumber: null,
      email: null,
      memo: null,
      confirmationCount: stat.count,
      outstanding: out.outstanding,
      paid: out.paid,
      lastWorkedDate: stat.lastDate ? toKstDateStr(stat.lastDate) : null,
    });
  }

  // 최근 작업일 desc (없으면 뒤로), 동률이면 이름 오름차순.
  items.sort((a, b) => {
    if (a.lastWorkedDate && b.lastWorkedDate) {
      if (a.lastWorkedDate !== b.lastWorkedDate) {
        return b.lastWorkedDate.localeCompare(a.lastWorkedDate);
      }
    } else if (a.lastWorkedDate) {
      return -1;
    } else if (b.lastWorkedDate) {
      return 1;
    }
    return a.name.localeCompare(b.name);
  });

  return items;
}
