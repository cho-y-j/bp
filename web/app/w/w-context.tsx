'use client';

import { createContext, useContext } from 'react';
import type { Me } from '../biz/biz-context';

export interface WorkerContextValue {
  me: Me | null;
  reload: () => void;
}

/**
 * 작업자 웹 컨텍스트 — /w 레이아웃이 Provider 로 감싸고 하위 페이지가 useWorker 로 소비.
 * (layout.tsx 는 Next.js 규약상 default 외 export 불가 → 별도 모듈)
 */
export const WorkerContext = createContext<WorkerContextValue>({
  me: null,
  reload: () => {},
});

export const useWorker = () => useContext(WorkerContext);
