import { normalizedRectToPdf } from './pdf.service';

describe('normalizedRectToPdf (마스킹 좌표 변환)', () => {
  const W = 600;
  const H = 800;

  it('좌상단 원점 → 좌하단 원점으로 y 반전', () => {
    const r = normalizedRectToPdf(
      { page: 0, x: 0.1, y: 0.2, width: 0.3, height: 0.05 },
      W,
      H,
    );
    expect(r.x).toBeCloseTo(60); // 0.1*600
    expect(r.width).toBeCloseTo(180); // 0.3*600
    expect(r.height).toBeCloseTo(40); // 0.05*800
    // y = H - y*H - height = 800 - 160 - 40 = 600
    expect(r.y).toBeCloseTo(600);
  });

  it('상단(y=0) 사각형 → PDF 상단(y = H - height)', () => {
    const r = normalizedRectToPdf(
      { page: 0, x: 0, y: 0, width: 1, height: 0.1 },
      W,
      H,
    );
    expect(r.x).toBeCloseTo(0);
    expect(r.y).toBeCloseTo(720); // 800 - 80
    expect(r.width).toBeCloseTo(600);
    expect(r.height).toBeCloseTo(80);
  });

  it('하단(y+height=1) 사각형 → PDF y=0', () => {
    const r = normalizedRectToPdf(
      { page: 0, x: 0, y: 0.9, width: 1, height: 0.1 },
      W,
      H,
    );
    expect(r.y).toBeCloseTo(0);
    expect(r.height).toBeCloseTo(80);
  });

  it('페이지 경계를 넘는 폭은 남은 공간으로 클램프', () => {
    const r = normalizedRectToPdf(
      { page: 0, x: 0.9, y: 0.2, width: 0.5, height: 0.05 },
      W,
      H,
    );
    // nx=0.9, nw=min(0.5, 0.1)=0.1 → width=60
    expect(r.x).toBeCloseTo(540);
    expect(r.width).toBeCloseTo(60);
  });

  it('음수 좌표는 0 으로 클램프', () => {
    const r = normalizedRectToPdf(
      { page: 0, x: -0.2, y: -0.1, width: 0.3, height: 0.1 },
      W,
      H,
    );
    expect(r.x).toBeCloseTo(0);
    expect(r.width).toBeCloseTo(180);
  });
});
