'use client';

import { createContext, useContext } from 'react';

export interface Me {
  id: string;
  name: string | null;
  phone: string;
  hasBusiness: boolean;
}

export interface BizContextValue {
  me: Me | null;
  business: { id: string; name: string; inviteCode?: string } | null;
  reload: () => void;
}

/**
 * 사업장 웹 컨텍스트 — layout 이 Provider 로 감싸고 하위 페이지가 useBiz 로 소비.
 * (layout.tsx 는 Next.js 규약상 default 컴포넌트 외 임의 export 불가 → 별도 모듈로 분리)
 */
export const BizContext = createContext<BizContextValue>({
  me: null,
  business: null,
  reload: () => {},
});

export const useBiz = () => useContext(BizContext);
