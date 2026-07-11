'use client';

import { createContext, useContext } from 'react';

export interface Me {
  id: string;
  name: string | null;
  phone: string;
  hasBusiness: boolean;
}

export interface Business {
  id: string;
  name: string;
  inviteCode?: string;
}

export interface BizContextValue {
  me: Me | null;
  /** 현재 선택된 사업장(단일 소유면 유일, 다중 소유면 드롭다운 선택값). */
  business: Business | null;
  /** 소유 사업장 전체(다중 소유 전환 UI 용). */
  businesses: Business[];
  /** 사업장 전환(선택값 localStorage 저장 + 컨텍스트 전파). */
  selectBusiness: (id: string) => void;
  reload: () => void;
}

/**
 * 사업장 웹 컨텍스트 — layout 이 Provider 로 감싸고 하위 페이지가 useBiz 로 소비.
 * (layout.tsx 는 Next.js 규약상 default 컴포넌트 외 임의 export 불가 → 별도 모듈로 분리)
 */
export const BizContext = createContext<BizContextValue>({
  me: null,
  business: null,
  businesses: [],
  selectBusiness: () => {},
  reload: () => {},
});

export const useBiz = () => useContext(BizContext);
