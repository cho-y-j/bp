import StatusScreen from '@/components/StatusScreen';

/** 404 — 무효/만료 링크, 존재하지 않는 경로. HTTP 404 로 응답된다. */
export default function NotFound() {
  return (
    <StatusScreen
      title="찾을 수 없는 링크입니다"
      message="링크가 만료되었거나 무효화되었을 수 있습니다. 보낸 분에게 새 링크를 요청하세요."
    />
  );
}
