import 'dart:math' as math;
import 'dart:ui';

/// 마스킹 사각형 — 페이지별 정규화(0~1) 좌표, 좌상단 원점.
/// 백엔드 `MaskRegionDto` 와 필드 일치.
class MaskRegion {
  final int page;
  final double x;
  final double y;
  final double width;
  final double height;
  const MaskRegion({
    this.page = 0,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
        'page': page,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  bool get isValid => width > 0 && height > 0;
}

double _clamp01(double v) => v.clamp(0.0, 1.0);

/// 표시 좌표계에서 드래그한 두 점(a,b) + 이미지 표시 크기 → 정규화 좌표 사각형.
/// 좌표 순서(역방향 드래그)와 캔버스 밖 이탈을 방어(clamp)한다.
MaskRegion normalizeDragRect(Offset a, Offset b, Size displaySize,
    {int page = 0}) {
  final w = displaySize.width <= 0 ? 1.0 : displaySize.width;
  final h = displaySize.height <= 0 ? 1.0 : displaySize.height;
  final left = math.min(a.dx, b.dx);
  final top = math.min(a.dy, b.dy);
  final right = math.max(a.dx, b.dx);
  final bottom = math.max(a.dy, b.dy);
  final nx = _clamp01(left / w);
  final ny = _clamp01(top / h);
  final nRight = _clamp01(right / w);
  final nBottom = _clamp01(bottom / h);
  return MaskRegion(
    page: page,
    x: nx,
    y: ny,
    width: nRight - nx,
    height: nBottom - ny,
  );
}

/// 정규화 사각형 → 표시 좌표계 Rect (미리보기에 다시 그릴 때).
Rect regionToDisplayRect(MaskRegion r, Size displaySize) => Rect.fromLTWH(
      r.x * displaySize.width,
      r.y * displaySize.height,
      r.width * displaySize.width,
      r.height * displaySize.height,
    );
