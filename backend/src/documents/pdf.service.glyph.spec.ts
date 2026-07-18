import { execFileSync } from 'child_process';
import { promises as fs } from 'fs';
import * as os from 'os';
import * as path from 'path';
import sharp from 'sharp';
import { PdfService } from './pdf.service';
import type { ConfirmationPdfData } from './pdf.types';

/**
 * ★1 회귀 방지 — PDF 글리프 렌더 검증 (2026-07-18 디자인 감사).
 *
 * 배경: @pdf-lib/fontkit 의 subset:true 매핑 버그로 생성 PDF 에서 숫자(0~9)·다수
 * 한글 글리프가 렌더되지 않았다. pdftotext 텍스트 레이어는 정상이라 텍스트 기반
 * 검사로는 잡히지 않는다. 따라서 (1) 폰트 전체 임베드 여부(바이트/FontFile2)와
 * (2) 실제 래스터 렌더 픽셀 유무 를 검사한다.
 */
describe('PDF 글리프 렌더 회귀 (subset 버그 방지)', () => {
  const svc = new PdfService();

  const sample: ConfirmationPdfData = {
    title: '작업확인서',
    date: '2026-07-06',
    companyName: '대한건설(주)',
    contact: '010-1234-5678',
    workerName: '김현수',
    site: '서울 강남 A현장',
    workContent: '터파기 굴착 작업 및 잔토 처리',
    timeRange: '08:00 ~ 17:00',
    rateTypeLabel: '일당',
    lines: [{ label: '기본 일당', detail: '350,000원 × 3일', amount: 1050000 }],
    subtotal: 1050000,
    vatRate: 0.1,
    vat: 105000,
    total: 1155000,
    notes: null,
    statusLabel: '서명됨',
  };

  it('폰트를 서브셋 없이 전체 임베드한다(충분한 폰트 바이트)', async () => {
    const buf = await svc.renderConfirmationPdf(sample);
    // 전체 임베드면 폰트 스트림이 커서 수백 KB 이상. subset:true(글리프 깨짐)로
    // 되돌아가면 폰트 스트림이 급감(수십 KB)하므로 이 하한선이 회귀를 막는다.
    expect(buf.length).toBeGreaterThan(300 * 1024);
  });

  const hasPdftoppm = (() => {
    try {
      execFileSync('pdftoppm', ['-h'], { stdio: 'ignore' });
      return true;
    } catch {
      // -h 는 poppler 에서 종료코드 0 이 아닐 수 있어 별도 확인
      try {
        execFileSync('which', ['pdftoppm'], { stdio: 'ignore' });
        return true;
      } catch {
        return false;
      }
    }
  })();

  // pdftoppm(poppler) 가 있는 환경에서만: 실제 래스터 렌더 후 잉크 픽셀 검사.
  (hasPdftoppm ? it : it.skip)(
    '래스터 렌더 시 글리프가 실제로 그려진다(잉크 픽셀 밀도)',
    async () => {
      const buf = await svc.renderConfirmationPdf(sample);
      const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'pdf-glyph-'));
      const pdfPath = path.join(dir, 'doc.pdf');
      const outPrefix = path.join(dir, 'page');
      try {
        await fs.writeFile(pdfPath, buf);
        // 100dpi PNG 로 래스터화
        execFileSync('pdftoppm', ['-png', '-r', '100', pdfPath, outPrefix], {
          stdio: 'ignore',
        });
        const pngPath = `${outPrefix}-1.png`;
        const { data, info } = await sharp(pngPath)
          .greyscale()
          .raw()
          .toBuffer({ resolveWithObject: true });
        let dark = 0;
        for (let i = 0; i < data.length; i++) {
          if (data[i] < 120) dark++;
        }
        const ratio = dark / (info.width * info.height);
        // 정상 렌더 ~0.008, 글리프 깨짐(숫자·다수 한글 누락) ~0.0027.
        // 0.005 를 경계로 잡으면 두 상태를 안정적으로 구분한다.
        expect(ratio).toBeGreaterThan(0.005);
      } finally {
        await fs.rm(dir, { recursive: true, force: true });
      }
    },
    30000,
  );
});
