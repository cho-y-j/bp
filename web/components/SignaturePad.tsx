'use client';

import {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from 'react';

export interface SignaturePadHandle {
  isEmpty: () => boolean;
  clear: () => void;
  toDataURL: () => string;
}

type Point = { x: number; y: number };

/**
 * 캔버스 터치 서명 패드 (라이브러리 없이 직접 구현).
 * Pointer Events 로 마우스·터치·펜 통합 처리. 고DPI 대응. PNG data URI 출력.
 *
 * 리사이즈 보존: 그린 획을 벡터 좌표(CSS px)로 보관(strokes)하고, 모바일 주소창
 * 접힘/키보드/회전 등 resize 이벤트에서 캔버스를 재초기화한 뒤 **기존 서명을 리드로우**한다.
 * (이전 구현은 resize 시 서명이 지워졌음)
 */
const SignaturePad = forwardRef<SignaturePadHandle, { onChange?: (empty: boolean) => void }>(
  function SignaturePad({ onChange }, ref) {
    const canvasRef = useRef<HTMLCanvasElement>(null);
    const drawing = useRef(false);
    const strokes = useRef<Point[][]>([]);
    const current = useRef<Point[] | null>(null);
    const [empty, setEmpty] = useState(true);

    /** 현재 캔버스 컨텍스트를 서명 스타일로 구성(리드로우 전에도 사용). */
    const styleCtx = (ctx: CanvasRenderingContext2D) => {
      ctx.lineWidth = 2.6;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      ctx.strokeStyle = '#1A2233'; // 진한 네이비 잉크
    };

    // 캔버스를 컨테이너 크기에 맞춰 고DPI 로 (재)초기화. transform=scale(dpr).
    const setup = () => {
      const canvas = canvasRef.current;
      if (!canvas) return;
      const rect = canvas.getBoundingClientRect();
      const dpr = window.devicePixelRatio || 1;
      canvas.width = Math.round(rect.width * dpr);
      canvas.height = Math.round(rect.height * dpr);
      const ctx = canvas.getContext('2d');
      if (!ctx) return;
      ctx.scale(dpr, dpr);
      styleCtx(ctx);
    };

    /** 보관된 모든 획을 현재(스케일된) 컨텍스트에 다시 그린다. */
    const redraw = () => {
      const canvas = canvasRef.current;
      const ctx = canvas?.getContext('2d');
      if (!canvas || !ctx) return;
      // 장치 픽셀 기준으로 전체 클리어 후, CSS px 좌표로 획 재현.
      ctx.save();
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.restore();
      styleCtx(ctx);
      for (const stroke of strokes.current) {
        if (stroke.length === 0) continue;
        ctx.beginPath();
        ctx.moveTo(stroke[0].x, stroke[0].y);
        if (stroke.length === 1) {
          // 단일 탭(점)도 보이도록 아주 짧은 선분.
          ctx.lineTo(stroke[0].x + 0.1, stroke[0].y + 0.1);
        } else {
          for (let i = 1; i < stroke.length; i++) {
            ctx.lineTo(stroke[i].x, stroke[i].y);
          }
        }
        ctx.stroke();
      }
    };

    useEffect(() => {
      setup();
      const onResize = () => {
        // 리사이즈 시 캔버스 재초기화 후 기존 서명 리드로우(픽셀 보존).
        setup();
        redraw();
      };
      window.addEventListener('resize', onResize);
      window.addEventListener('orientationchange', onResize);
      return () => {
        window.removeEventListener('resize', onResize);
        window.removeEventListener('orientationchange', onResize);
      };
      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const pos = (e: React.PointerEvent<HTMLCanvasElement>): Point => {
      const canvas = canvasRef.current!;
      const rect = canvas.getBoundingClientRect();
      return { x: e.clientX - rect.left, y: e.clientY - rect.top };
    };

    const start = (e: React.PointerEvent<HTMLCanvasElement>) => {
      e.preventDefault();
      try {
        canvasRef.current?.setPointerCapture(e.pointerId);
      } catch {
        /* 포인터 캡처 불가(합성 이벤트 등) 시 무시 */
      }
      drawing.current = true;
      const p = pos(e);
      current.current = [p];
      if (empty) {
        setEmpty(false);
        onChange?.(false);
      }
    };
    const move = (e: React.PointerEvent<HTMLCanvasElement>) => {
      if (!drawing.current) return;
      e.preventDefault();
      const ctx = canvasRef.current?.getContext('2d');
      const stroke = current.current;
      if (!ctx || !stroke) return;
      const p = pos(e);
      const prev = stroke[stroke.length - 1];
      ctx.beginPath();
      ctx.moveTo(prev.x, prev.y);
      ctx.lineTo(p.x, p.y);
      ctx.stroke();
      stroke.push(p);
    };
    const end = (e: React.PointerEvent<HTMLCanvasElement>) => {
      if (drawing.current && current.current && current.current.length > 0) {
        strokes.current.push(current.current);
        // 단일 탭(점)도 화면에 즉시 보이도록.
        if (current.current.length === 1) redraw();
      }
      current.current = null;
      drawing.current = false;
      try {
        canvasRef.current?.releasePointerCapture(e.pointerId);
      } catch {
        /* noop */
      }
    };

    useImperativeHandle(ref, () => ({
      isEmpty: () => strokes.current.length === 0 && !current.current,
      clear: () => {
        const canvas = canvasRef.current;
        const ctx = canvas?.getContext('2d');
        if (canvas && ctx) {
          ctx.save();
          ctx.setTransform(1, 0, 0, 1, 0, 0);
          ctx.clearRect(0, 0, canvas.width, canvas.height);
          ctx.restore();
        }
        strokes.current = [];
        current.current = null;
        drawing.current = false;
        setEmpty(true);
        onChange?.(true);
      },
      toDataURL: () => canvasRef.current?.toDataURL('image/png') ?? '',
    }));

    return (
      <div className={`sign-canvas-wrap${empty ? '' : ' filled'}`}>
        <canvas
          ref={canvasRef}
          className="sign-canvas"
          onPointerDown={start}
          onPointerMove={move}
          onPointerUp={end}
          onPointerLeave={end}
          onPointerCancel={end}
          aria-label="서명 입력 영역"
        />
        {empty ? (
          <>
            <span className="sign-baseline" />
            <span className="sign-hint">여기에 손가락 또는 마우스로 서명하세요</span>
          </>
        ) : null}
      </div>
    );
  },
);

export default SignaturePad;
