import axios, { AxiosError, type AxiosInstance } from 'axios';

/**
 * 브라우저용 API 베이스 (전역 prefix /api 포함).
 * - 기본값은 상대경로 `/api` → 배포 시 nginx 동일 오리진으로 프록시된다(HTTPS 그대로).
 *   (build 시점에 도메인을 몰라도 되고, 브라우저가 현재 오리진 기준으로 요청)
 * - 로컬 dev 는 web/.env.local 의 NEXT_PUBLIC_API_URL(예: http://localhost:3010/api)로 절대 지정.
 */
export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? '/api';

/** API 호스트 오리진 — 서버가 돌려주는 상대경로(/api/...) 를 절대 URL 로 만들 때 사용.
 *  상대 base(`/api`)면 origin 은 빈 문자열 → absoluteUrl 이 상대경로를 그대로 반환(브라우저가 현재 오리진으로 해석). */
export const API_ORIGIN = /^https?:\/\//.test(API_URL)
  ? API_URL.replace(/\/api\/?$/, '')
  : '';

/**
 * SSR(서버 컴포넌트) 전용 API 베이스 — 컨테이너 내부에서 api 서비스로 직접 접속.
 * fetch 는 절대 URL 이 필요하므로 상대경로를 쓸 수 없다.
 * - 배포(compose): API_INTERNAL_URL=http://api:3000/api (런타임 서버 전용 env, 빌드에 박히지 않음)
 * - 로컬 dev: NEXT_PUBLIC_API_URL 로 폴백.
 */
const SSR_API_URL =
  process.env.API_INTERNAL_URL ??
  process.env.NEXT_PUBLIC_API_URL ??
  'http://localhost:3010/api';

/** 서버가 돌려준 상대 경로(pdfUrl, fileUrl 등)를 절대 URL 로. */
export function absoluteUrl(path: string): string {
  if (/^https?:\/\//.test(path)) return path;
  return `${API_ORIGIN}${path.startsWith('/') ? '' : '/'}${path}`;
}

/** 공개 SSR fetch 타임아웃(ms). 백엔드 지연/무응답에도 페이지가 오래 멈추지 않도록. */
const SSR_TIMEOUT_MS = 8000;

/**
 * { data, error } 봉투 언래핑 (서버 컴포넌트/SSR 용 순수 fetch).
 * - AbortController 로 8초 타임아웃.
 * - API 가 4xx/5xx 로 응답하면 status 를 담은 ApiError.
 * - 네트워크 오류/타임아웃(백엔드 다운 등)은 status=0 인 ApiError('NETWORK'/'TIMEOUT').
 *   → 호출부가 "무효 토큰(4xx=404)" 과 "일시 장애(0·5xx=친화 화면)" 를 구분할 수 있다.
 */
export async function apiGet<T>(path: string): Promise<T> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), SSR_TIMEOUT_MS);
  let res: Response;
  try {
    res = await fetch(`${SSR_API_URL}${path}`, {
      cache: 'no-store',
      signal: controller.signal,
    });
  } catch (e) {
    const aborted = e instanceof Error && e.name === 'AbortError';
    throw new ApiError(
      aborted ? 'TIMEOUT' : 'NETWORK',
      aborted
        ? '서버 응답이 지연되고 있습니다.'
        : '서버에 연결할 수 없습니다.',
      0,
    );
  } finally {
    clearTimeout(timer);
  }
  const body = (await res.json().catch(() => null)) as
    | { data?: T; error?: { code: string; message: string } }
    | null;
  if (!res.ok || !body || body.error) {
    const err = body?.error;
    throw new ApiError(
      err?.code ?? `HTTP_${res.status}`,
      err?.message ?? '요청을 처리할 수 없습니다.',
      res.status,
    );
  }
  return body.data as T;
}

/** ApiError 를 "무효/만료 토큰(4xx)" 과 "일시 장애(네트워크·타임아웃·5xx)" 로 분류. */
export function classifyLoadError(e: unknown): 'notfound' | 'transient' {
  if (e instanceof ApiError) {
    if (e.status >= 400 && e.status < 500) return 'notfound';
    return 'transient'; // status 0(네트워크/타임아웃) 또는 5xx
  }
  return 'transient';
}

export class ApiError extends Error {
  constructor(
    public code: string,
    message: string,
    public status: number,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

const TOKEN_KEY = 'jakeobon_token';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return window.localStorage.getItem(TOKEN_KEY);
}
export function setToken(token: string): void {
  window.localStorage.setItem(TOKEN_KEY, token);
}
export function clearToken(): void {
  window.localStorage.removeItem(TOKEN_KEY);
}

/**
 * 사업장 웹(클라이언트) 전용 axios 인스턴스.
 * - 요청 인터셉터: localStorage JWT 를 Authorization 헤더로 주입
 * - 응답 인터셉터: { data } 봉투 언래핑, 401 이면 로그인으로 리다이렉트
 */
let _client: AxiosInstance | null = null;
export function api(): AxiosInstance {
  if (_client) return _client;
  const instance = axios.create({ baseURL: API_URL });

  instance.interceptors.request.use((config) => {
    const token = getToken();
    if (token) {
      config.headers = config.headers ?? {};
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  });

  instance.interceptors.response.use(
    (res) => {
      // 봉투 언래핑: { data } → data. (blob 응답 등은 그대로.)
      if (res.data && typeof res.data === 'object' && 'data' in res.data) {
        res.data = (res.data as { data: unknown }).data;
      }
      return res;
    },
    (error: AxiosError<{ error?: { code: string; message: string } }>) => {
      if (error.response?.status === 401 && typeof window !== 'undefined') {
        clearToken();
        const here = window.location.pathname + window.location.search;
        if (!window.location.pathname.startsWith('/login')) {
          window.location.href = `/login?next=${encodeURIComponent(here)}`;
        }
      }
      const env = error.response?.data?.error;
      return Promise.reject(
        new ApiError(
          env?.code ?? error.code ?? 'NETWORK',
          env?.message ?? error.message ?? '네트워크 오류',
          error.response?.status ?? 0,
        ),
      );
    },
  );

  _client = instance;
  return instance;
}

/** 인증이 필요한 PDF/파일을 blob 으로 받아 새 탭 or 다운로드. */
export async function authedBlob(path: string): Promise<Blob> {
  const res = await api().get(path, { responseType: 'blob' });
  return res.data as Blob;
}
