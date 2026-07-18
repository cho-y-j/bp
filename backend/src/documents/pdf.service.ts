import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { PDFDocument, PDFFont, PDFPage, rgb } from 'pdf-lib';
import fontkit from '@pdf-lib/fontkit';
import sharp from 'sharp';
import heicConvert from 'heic-convert';
import * as path from 'path';
import { promises as fs } from 'fs';
import { AppException } from '../common/errors';
import type {
  ConfirmationPdfData,
  IncomeReportPdfData,
  LaborContractPdfData,
  SafetyReportPdfData,
  SiteCostsPdfData,
  StatementPdfData,
} from './pdf.types';

/** 정규화 0~1 좌표(좌상단 원점)의 마스킹 사각형. */
export interface NormalizedRect {
  page: number; // 0-based 페이지 인덱스
  x: number; // 0~1 (왼쪽에서)
  y: number; // 0~1 (위에서)
  width: number; // 0~1
  height: number; // 0~1
}

/** PDF 좌표(좌하단 원점, 포인트 단위) 사각형. */
export interface PdfRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

const clamp01 = (n: number): number => Math.min(1, Math.max(0, n));

/**
 * 정규화 사각형(좌상단 원점, 0~1) → PDF 사각형(좌하단 원점, 포인트).
 * 순수 함수 — 단위 테스트 대상.
 *  - x 는 그대로 스케일, y 는 상하 반전(PDF 는 아래가 원점).
 *  - 페이지 경계를 벗어나지 않도록 0~1 로 클램프한 뒤 변환한다.
 */
export function normalizedRectToPdf(
  rect: NormalizedRect,
  pageWidth: number,
  pageHeight: number,
): PdfRect {
  const nx = clamp01(rect.x);
  const ny = clamp01(rect.y);
  // 폭/높이는 남은 공간을 넘지 않게 클램프
  const nw = clamp01(Math.min(rect.width, 1 - nx));
  const nh = clamp01(Math.min(rect.height, 1 - ny));

  const width = nw * pageWidth;
  const height = nh * pageHeight;
  const x = nx * pageWidth;
  // 좌상단 y → 좌하단 y 로 변환 (사각형 하단 모서리 기준)
  const y = pageHeight - ny * pageHeight - height;
  return { x, y, width, height };
}

const ALLOWED_IMAGE_MIME = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);

// ── 디자인 토큰 (DESIGN-UI.md 컬러 팔레트) ──────────────────────────────────
const INK = rgb(0.102, 0.133, 0.2); // #1A2233 딥 네이비 (본문/헤딩)
const MUTED = rgb(0.4, 0.43, 0.49); // 라벨/보조 텍스트
const ORANGE = rgb(0.957, 0.467, 0.047); // #F4770C 안전 오렌지 (브랜드 포인트)
const ORANGE_DARK = rgb(0.761, 0.255, 0.047); // #C2410C 미수/강조 금액
const GREEN = rgb(0.082, 0.502, 0.239); // #15803D 입금
const PAPER = rgb(0.969, 0.965, 0.953); // #F7F6F3 종이톤 (표 헤더/줄무늬)
const BORDER = rgb(0.886, 0.875, 0.847); // #E2DFD8 옅은 종이 경계
const TOTAL_FILL = rgb(0.992, 0.949, 0.906); // #FDF2E7 합계 박스 배경(옅은 오렌지)
const STAMP_FILL = rgb(0.997, 0.994, 0.988); // 서명 박스 배경
const A4: [number, number] = [595.28, 841.89];
const MARGIN = 48;
const FOOTER_TEXT = '작업온에서 발행 · workon';

interface Fonts {
  regular: PDFFont;
  bold: PDFFont;
}

@Injectable()
export class PdfService {
  private readonly logger = new Logger('PdfService');

  /**
   * 업로드 파일을 PDF 로 정규화한다.
   *  - PDF: 파싱 검증 후 그대로 반환.
   *  - 이미지(jpg/png/webp/heic): 단일 페이지 PDF 로 변환(이미지 원본 크기 유지, EXIF 회전 반영).
   */
  async normalizeToPdf(buffer: Buffer, mime: string): Promise<Buffer> {
    if (mime === 'application/pdf') {
      // 유효한 PDF 인지 파싱 검증 (암호화본은 허용하되 편집 시 재확인)
      try {
        await PDFDocument.load(buffer, { ignoreEncryption: true });
      } catch {
        throw new AppException(
          'INVALID_PDF',
          '손상되었거나 열 수 없는 PDF 입니다.',
          HttpStatus.BAD_REQUEST,
        );
      }
      return buffer;
    }

    if (!ALLOWED_IMAGE_MIME.has(mime)) {
      throw new AppException(
        'UNSUPPORTED_FILE_TYPE',
        '지원하지 않는 파일 형식입니다.',
        HttpStatus.BAD_REQUEST,
      );
    }

    // HEIC/HEIF → JPEG 로 1차 변환 (sharp 빌드가 heif 미지원일 수 있어 안전하게 처리)
    let imageBuffer = buffer;
    if (mime === 'image/heic' || mime === 'image/heif') {
      const out = await heicConvert({
        buffer, // Buffer 는 Uint8Array 호환
        format: 'JPEG',
        quality: 0.92,
      });
      imageBuffer = Buffer.from(out);
    }

    // EXIF 방향 보정 후 PNG 로 표준화
    let pngBuffer: Buffer;
    let width: number;
    let height: number;
    try {
      const pipeline = sharp(imageBuffer).rotate(); // rotate() = EXIF 자동 보정
      pngBuffer = await pipeline.png().toBuffer();
      const meta = await sharp(pngBuffer).metadata();
      width = meta.width ?? 0;
      height = meta.height ?? 0;
    } catch (e) {
      this.logger.warn(`이미지 처리 실패: ${(e as Error).message}`);
      throw new AppException(
        'INVALID_IMAGE',
        '이미지를 처리할 수 없습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    if (!width || !height) {
      throw new AppException(
        'INVALID_IMAGE',
        '이미지 크기를 확인할 수 없습니다.',
        HttpStatus.BAD_REQUEST,
      );
    }

    const pdf = await PDFDocument.create();
    const png = await pdf.embedPng(pngBuffer);
    const page = pdf.addPage([width, height]);
    page.drawImage(png, { x: 0, y: 0, width, height });
    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /**
   * PDF 위에 검정 사각형을 오버레이한 마스킹본을 만든다.
   * regions 의 좌표는 페이지별 정규화(0~1, 좌상단 원점).
   */
  async applyMask(
    pdfBuffer: Buffer,
    regions: NormalizedRect[],
  ): Promise<Buffer> {
    const pdf = await PDFDocument.load(pdfBuffer, { ignoreEncryption: true });
    const pageCount = pdf.getPageCount();

    for (const region of regions) {
      if (
        !Number.isInteger(region.page) ||
        region.page < 0 ||
        region.page >= pageCount
      ) {
        throw new AppException(
          'INVALID_MASK_PAGE',
          `마스킹 페이지 번호가 범위를 벗어났습니다 (0~${pageCount - 1}).`,
          HttpStatus.BAD_REQUEST,
        );
      }
      const page = pdf.getPage(region.page);
      const { width, height } = page.getSize();
      const r = normalizedRectToPdf(region, width, height);
      if (r.width <= 0 || r.height <= 0) continue; // 빈 영역은 건너뜀
      page.drawRectangle({
        x: r.x,
        y: r.y,
        width: r.width,
        height: r.height,
        color: rgb(0, 0, 0),
        opacity: 1,
        borderWidth: 0,
      });
    }

    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /** PDF 페이지 수 (검증/보고용). */
  async pageCount(pdfBuffer: Buffer): Promise<number> {
    const pdf = await PDFDocument.load(pdfBuffer, { ignoreEncryption: true });
    return pdf.getPageCount();
  }

  // ==========================================================================
  //  한글 폰트 임베드 (확인서/명세서 PDF)
  //  - 로컬 OFL 폰트(NanumGothic Regular/Bold)를 전체 임베드한다.
  //  - ★ subset:true 는 @pdf-lib/fontkit 의 서브셋 매핑 버그로 숫자(0~9)·다수
  //    한글 글리프가 렌더되지 않는다(2026-07-18 감사 ★1). 반드시 subset:false
  //    (전체 임베드)로 사용한다. 검증: pdftoppm 래스터 렌더 후 육안/픽셀 검사.
  // ==========================================================================
  private fontRegularCache: Buffer | null = null;
  private fontBoldCache: Buffer | null = null;

  private async loadFontFile(fileName: string): Promise<Buffer> {
    // dist 빌드/소스 실행 모두에서 찾도록 후보 경로 탐색
    const candidates = [
      path.resolve(__dirname, `../../assets/fonts/${fileName}`),
      path.resolve(process.cwd(), `assets/fonts/${fileName}`),
    ];
    for (const p of candidates) {
      try {
        return await fs.readFile(p);
      } catch {
        // 다음 후보
      }
    }
    throw new AppException(
      'FONT_NOT_FOUND',
      `한글 폰트 파일을 찾을 수 없습니다 (assets/fonts/${fileName}).`,
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }

  /** 문서용 폰트(정체/굵게)를 등록·임베드한다. subset:false 필수. */
  private async embedFonts(pdf: PDFDocument): Promise<Fonts> {
    pdf.registerFontkit(fontkit);
    if (!this.fontRegularCache) {
      this.fontRegularCache = await this.loadFontFile(
        'NanumGothic-Regular.ttf',
      );
    }
    if (!this.fontBoldCache) {
      this.fontBoldCache = await this.loadFontFile('NanumGothic-Bold.ttf');
    }
    const regular = await pdf.embedFont(this.fontRegularCache, {
      subset: false,
    });
    const bold = await pdf.embedFont(this.fontBoldCache, { subset: false });
    return { regular, bold };
  }

  private krw(n: number): string {
    return `${Math.round(n).toLocaleString('ko-KR')}원`;
  }

  private issueDate(): string {
    const d = new Date();
    const p = (v: number) => String(v).padStart(2, '0');
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
  }

  /** 폭 초과 문자열을 말줄임(…)으로 자른다. */
  private clip(font: PDFFont, s: string, size: number, maxW: number): string {
    const src = s ?? '';
    let shown = src;
    while (font.widthOfTextAtSize(shown, size) > maxW && shown.length > 1) {
      shown = shown.slice(0, -1);
    }
    return shown !== src ? shown.slice(0, -1) + '…' : shown;
  }

  // ── 공통 레이아웃 헬퍼 ────────────────────────────────────────────────
  /**
   * 문서 상단 헤더: 문서명(크게·굵게) + 부제 + 우측 발행처/발행일(+옵션).
   * 하단에 네이비 괘선 + 좌측 오렌지 포인트. 본문 시작 y 를 반환한다.
   */
  private drawHeader(
    page: PDFPage,
    fonts: Fonts,
    title: string,
    subtitle: string | null,
    rightExtra: string[] = [],
  ): number {
    const W = page.getWidth();
    const H = page.getHeight();
    const top = H - MARGIN;
    const titleSize = 24;
    page.drawText(title, {
      x: MARGIN,
      y: top - titleSize,
      size: titleSize,
      font: fonts.bold,
      color: INK,
    });
    if (subtitle) {
      page.drawText(subtitle, {
        x: MARGIN,
        y: top - titleSize - 16,
        size: 11,
        font: fonts.regular,
        color: MUTED,
      });
    }
    const rlines = [
      '발행처  작업온 (workon)',
      `발행일  ${this.issueDate()}`,
      ...rightExtra,
    ];
    let ry = top - 6;
    for (const l of rlines) {
      const w = fonts.regular.widthOfTextAtSize(l, 9);
      page.drawText(l, {
        x: W - MARGIN - w,
        y: ry,
        size: 9,
        font: fonts.regular,
        color: MUTED,
      });
      ry -= 13;
    }
    // 괘선은 제목/부제 아래이면서 우측 발행정보 블록보다도 아래에 오도록 한다.
    const titleRuleY = top - titleSize - (subtitle ? 30 : 16);
    const ruleY = Math.min(titleRuleY, ry + 3);
    page.drawLine({
      start: { x: MARGIN, y: ruleY },
      end: { x: W - MARGIN, y: ruleY },
      thickness: 1.2,
      color: INK,
    });
    page.drawRectangle({
      x: MARGIN,
      y: ruleY - 1.5,
      width: 70,
      height: 3,
      color: ORANGE,
    });
    return ruleY - 26;
  }

  /** 모든 페이지 하단에 "작업온에서 발행" 푸터 + (다중페이지 시)쪽 번호. */
  private stampFooters(pdf: PDFDocument, fonts: Fonts): void {
    const pages = pdf.getPages();
    const total = pages.length;
    pages.forEach((page, i) => {
      const W = page.getWidth();
      const fy = 30;
      page.drawLine({
        start: { x: MARGIN, y: fy + 13 },
        end: { x: W - MARGIN, y: fy + 13 },
        thickness: 0.5,
        color: BORDER,
      });
      page.drawText(FOOTER_TEXT, {
        x: MARGIN,
        y: fy,
        size: 8,
        font: fonts.regular,
        color: MUTED,
      });
      if (total > 1) {
        const pn = `${i + 1} / ${total}`;
        const w = fonts.regular.widthOfTextAtSize(pn, 8);
        page.drawText(pn, {
          x: W - MARGIN - w,
          y: fy,
          size: 8,
          font: fonts.regular,
          color: MUTED,
        });
      }
    });
  }

  /** 섹션 제목(오렌지 좌측 바 + 굵은 라벨). 본문 시작 y 반환. */
  private sectionTitle(
    page: PDFPage,
    fonts: Fonts,
    label: string,
    y: number,
    rightNote?: string,
  ): number {
    page.drawRectangle({
      x: MARGIN,
      y: y - 1,
      width: 4,
      height: 13,
      color: ORANGE,
    });
    page.drawText(label, {
      x: MARGIN + 12,
      y,
      size: 12,
      font: fonts.bold,
      color: INK,
    });
    if (rightNote) {
      const W = page.getWidth();
      const w = fonts.regular.widthOfTextAtSize(rightNote, 10);
      page.drawText(rightNote, {
        x: W - MARGIN - w,
        y,
        size: 10,
        font: fonts.regular,
        color: MUTED,
      });
    }
    return y - 22;
  }

  /** 라벨/값 2열 괘선 표. 본문 다음 y 반환. */
  private drawKeyValueTable(
    page: PDFPage,
    fonts: Fonts,
    x: number,
    yTop: number,
    width: number,
    rows: Array<[string, string]>,
    labelColW = 120,
  ): number {
    const rowH = 24;
    let y = yTop;
    rows.forEach(([label, value], i) => {
      const rowBot = y - rowH;
      if (i % 2 === 1) {
        page.drawRectangle({ x, y: rowBot, width, height: rowH, color: PAPER });
      }
      const baseY = rowBot + 8;
      page.drawText(label, {
        x: x + 12,
        y: baseY,
        size: 10.5,
        font: fonts.regular,
        color: MUTED,
      });
      const valMaxW = width - labelColW - 20;
      page.drawText(this.clip(fonts.regular, value ?? '', 11, valMaxW), {
        x: x + labelColW,
        y: baseY,
        size: 11,
        font: fonts.regular,
        color: INK,
      });
      page.drawLine({
        start: { x, y: rowBot },
        end: { x: x + width, y: rowBot },
        thickness: 0.4,
        color: BORDER,
      });
      y = rowBot;
    });
    // 외곽 박스 + 상단 괘선 + 라벨/값 구분선
    page.drawRectangle({
      x,
      y,
      width,
      height: yTop - y,
      borderColor: BORDER,
      borderWidth: 0.8,
    });
    page.drawLine({
      start: { x: x + labelColW - 12, y: yTop },
      end: { x: x + labelColW - 12, y },
      thickness: 0.4,
      color: BORDER,
    });
    return y - 16;
  }

  /** 합계 강조 박스(옅은 오렌지 배경 + 오렌지 테두리 + 큰 굵은 금액). */
  private drawTotalBox(
    page: PDFPage,
    fonts: Fonts,
    x: number,
    yTop: number,
    width: number,
    label: string,
    value: string,
  ): number {
    const boxH = 42;
    const boxY = yTop - boxH;
    page.drawRectangle({
      x,
      y: boxY,
      width,
      height: boxH,
      color: TOTAL_FILL,
      borderColor: ORANGE,
      borderWidth: 1.2,
    });
    page.drawText(label, {
      x: x + 16,
      y: boxY + boxH / 2 - 5,
      size: 12,
      font: fonts.bold,
      color: INK,
    });
    const vSize = 16;
    const w = fonts.bold.widthOfTextAtSize(value, vSize);
    page.drawText(value, {
      x: x + width - 16 - w,
      y: boxY + boxH / 2 - 6,
      size: vSize,
      font: fonts.bold,
      color: ORANGE_DARK,
    });
    return boxY - 16;
  }

  /**
   * 서명 도장 박스: 라벨 + 이중 테두리 박스(서명 이미지 or 미서명) + 서명자명 + 일시.
   * 박스 하단 y 를 반환한다.
   */
  private async drawSignatureStamp(
    pdf: PDFDocument,
    page: PDFPage,
    fonts: Fonts,
    x: number,
    yTop: number,
    width: number,
    label: string,
    signerName?: string | null,
    signedAt?: string | null,
    png?: Buffer | null,
  ): Promise<number> {
    page.drawText(label, {
      x,
      y: yTop,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    const boxH = 66;
    const boxY = yTop - 10 - boxH;
    // 이중 테두리로 "도장/직인" 느낌
    page.drawRectangle({
      x,
      y: boxY,
      width,
      height: boxH,
      color: STAMP_FILL,
      borderColor: BORDER,
      borderWidth: 1,
    });
    page.drawRectangle({
      x: x + 3,
      y: boxY + 3,
      width: width - 6,
      height: boxH - 6,
      borderColor: rgb(0.93, 0.91, 0.87),
      borderWidth: 0.4,
    });
    if (png) {
      try {
        const img = await pdf.embedPng(png);
        const scale = Math.min(
          (width - 16) / img.width,
          (boxH - 16) / img.height,
          1,
        );
        const w = img.width * scale;
        const h = img.height * scale;
        page.drawImage(img, {
          x: x + (width - w) / 2,
          y: boxY + (boxH - h) / 2,
          width: w,
          height: h,
        });
      } catch (e) {
        this.logger.warn(`서명 이미지 삽입 실패: ${(e as Error).message}`);
      }
    } else {
      const t = '(미서명)';
      const w = fonts.regular.widthOfTextAtSize(t, 11);
      page.drawText(t, {
        x: x + (width - w) / 2,
        y: boxY + boxH / 2 - 4,
        size: 11,
        font: fonts.regular,
        color: MUTED,
      });
    }
    const infoY = boxY - 15;
    page.drawText(
      signerName ? `서명자  ${signerName}` : '서명자  ____________',
      {
        x,
        y: infoY,
        size: 10,
        font: fonts.regular,
        color: INK,
      },
    );
    if (signedAt) {
      page.drawText(`서명일시  ${signedAt}`, {
        x,
        y: infoY - 14,
        size: 8,
        font: fonts.regular,
        color: MUTED,
      });
    }
    return infoY - (signedAt ? 14 : 0);
  }

  /** 작업확인서 PDF (종이 확인서 레이아웃). 서명 이미지가 있으면 서명란에 삽입. */
  async renderConfirmationPdf(data: ConfirmationPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    const fonts = await this.embedFonts(pdf);
    const page = pdf.addPage(A4);
    const W = page.getWidth();
    const contentW = W - 2 * MARGIN;

    let y = this.drawHeader(page, fonts, data.title, data.site || null, [
      `상태  ${data.statusLabel}`,
    ]);

    // 기본 정보 표
    const infoRows: Array<[string, string]> = [
      ['작성일', data.date],
      [
        '지시자(회사)',
        data.companyName + (data.contact ? ` (${data.contact})` : ''),
      ],
      ['작업자', data.workerName],
      ['작업 내용', data.workContent],
      ['작업 시간', data.timeRange],
      ['단가 유형', data.rateTypeLabel],
    ];
    y = this.drawKeyValueTable(page, fonts, MARGIN, y, contentW, infoRows, 110);

    // 장비 섹션(옵션)
    if (data.equipment) {
      y = this.sectionTitle(page, fonts, '장비', y);
      const e = data.equipment;
      const parts = [
        e.name ? `장비명 ${e.name}` : null,
        e.vehicleNumber ? `차량번호 ${e.vehicleNumber}` : null,
        e.spec ? `규격 ${e.spec}` : null,
        `유도원 ${e.guide ? '있음' : '없음'}`,
      ].filter(Boolean) as string[];
      page.drawText(this.clip(fonts.regular, parts.join('   '), 10, contentW), {
        x: MARGIN,
        y,
        size: 10,
        font: fonts.regular,
        color: INK,
      });
      y -= 24;
    }

    const amtRight = W - MARGIN;

    // 팀(반장) 명단 표
    if (data.teamEntries && data.teamEntries.length > 0) {
      y = this.sectionTitle(page, fonts, '팀 명단', y);
      const c = {
        name: MARGIN + 12,
        gongsu: MARGIN + 250,
        rate: MARGIN + 360,
        amount: amtRight - 12,
      };
      // 헤더 밴드
      page.drawRectangle({
        x: MARGIN,
        y: y - 6,
        width: contentW,
        height: 20,
        color: PAPER,
      });
      const hy = y - 2;
      page.drawText('이름', {
        x: c.name,
        y: hy,
        size: 10,
        font: fonts.bold,
        color: MUTED,
      });
      const rh = (t: string, xr: number) =>
        page.drawText(t, {
          x: xr - fonts.bold.widthOfTextAtSize(t, 10),
          y: hy,
          size: 10,
          font: fonts.bold,
          color: MUTED,
        });
      rh('공수', c.gongsu);
      rh('단가', c.rate);
      rh('금액', c.amount);
      y -= 22;
      for (const m of data.teamEntries) {
        page.drawText(this.clip(fonts.regular, m.name, 11, 200), {
          x: c.name,
          y,
          size: 11,
          font: fonts.regular,
          color: INK,
        });
        const cell = (t: string, xr: number, bold = false) =>
          page.drawText(t, {
            x:
              xr - (bold ? fonts.bold : fonts.regular).widthOfTextAtSize(t, 11),
            y,
            size: 11,
            font: bold ? fonts.bold : fonts.regular,
            color: INK,
          });
        cell(`${m.quantity}`, c.gongsu);
        cell(m.rate.toLocaleString('ko-KR'), c.rate);
        cell(this.krw(m.amount), c.amount, true);
        page.drawLine({
          start: { x: MARGIN, y: y - 7 },
          end: { x: W - MARGIN, y: y - 7 },
          thickness: 0.4,
          color: BORDER,
        });
        y -= 22;
      }
      y -= 6;
    }

    // 금액 표
    y = this.sectionTitle(page, fonts, '금액 내역', y);
    const col = {
      item: MARGIN + 12,
      detail: MARGIN + 170,
      amount: amtRight - 12,
    };
    page.drawRectangle({
      x: MARGIN,
      y: y - 6,
      width: contentW,
      height: 20,
      color: PAPER,
    });
    const hy = y - 2;
    page.drawText('항목', {
      x: col.item,
      y: hy,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    page.drawText('단가 × 수량', {
      x: col.detail,
      y: hy,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    const amtHdr = '금액';
    page.drawText(amtHdr, {
      x: col.amount - fonts.bold.widthOfTextAtSize(amtHdr, 10),
      y: hy,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    y -= 22;
    const amountRow = (label: string, detail: string, amount: number) => {
      page.drawText(this.clip(fonts.regular, label, 11, 150), {
        x: col.item,
        y,
        size: 11,
        font: fonts.regular,
        color: INK,
      });
      page.drawText(
        this.clip(fonts.regular, detail, 10, col.amount - col.detail - 80),
        {
          x: col.detail,
          y,
          size: 10,
          font: fonts.regular,
          color: MUTED,
        },
      );
      const a = this.krw(amount);
      page.drawText(a, {
        x: col.amount - fonts.regular.widthOfTextAtSize(a, 11),
        y,
        size: 11,
        font: fonts.regular,
        color: INK,
      });
      page.drawLine({
        start: { x: MARGIN, y: y - 7 },
        end: { x: W - MARGIN, y: y - 7 },
        thickness: 0.4,
        color: BORDER,
      });
      y -= 22;
    };
    for (const li of data.lines) amountRow(li.label, li.detail, li.amount);
    if (
      data.teamEntries &&
      data.teamEntries.length > 0 &&
      data.lines.length === 0
    ) {
      amountRow(
        '팀 작업 합계',
        `팀원 ${data.teamEntries.length}명`,
        data.subtotal,
      );
    }

    // 공급가/부가세 + 합계 강조 박스
    y -= 4;
    const putRight = (label: string, value: string) => {
      page.drawText(label, {
        x: col.detail,
        y,
        size: 11,
        font: fonts.regular,
        color: MUTED,
      });
      page.drawText(value, {
        x: col.amount - fonts.regular.widthOfTextAtSize(value, 11),
        y,
        size: 11,
        font: fonts.regular,
        color: INK,
      });
      y -= 20;
    };
    putRight('공급가 합계', this.krw(data.subtotal));
    if (data.vatRate > 0) {
      putRight(
        `부가세 (${Math.round(data.vatRate * 100)}%)`,
        this.krw(data.vat),
      );
    }
    y -= 2;
    y = this.drawTotalBox(
      page,
      fonts,
      MARGIN + contentW / 2,
      y + 12,
      contentW / 2,
      '청구 합계',
      this.krw(data.total),
    );

    // 특이사항
    if (data.notes) {
      y -= 2;
      y = this.sectionTitle(page, fonts, '특이사항', y);
      y = this.drawWrapped(
        page,
        fonts,
        data.notes,
        MARGIN,
        y,
        contentW,
        10,
        MUTED,
      );
    }

    // 서명 도장 박스 (하단 우측)
    const sigTop = MARGIN + 130;
    await this.drawSignatureStamp(
      pdf,
      page,
      fonts,
      W - MARGIN - 200,
      sigTop,
      200,
      '작업 확인 서명',
      data.signerName,
      data.signedAt,
      data.signImagePng,
    );

    this.stampFooters(pdf, fonts);
    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /** 지정 폭 내 자동 줄바꿈 렌더. 다음 y 반환. */
  private drawWrapped(
    page: PDFPage,
    fonts: Fonts,
    s: string,
    x: number,
    yStart: number,
    maxW: number,
    size: number,
    color = INK,
    lineGap = 6,
  ): number {
    let y = yStart;
    let buf = '';
    const flush = () => {
      page.drawText(buf, { x, y, size, font: fonts.regular, color });
      y -= size + lineGap;
      buf = '';
    };
    for (const ch of s) {
      if (ch === '\n') {
        flush();
        continue;
      }
      const test = buf + ch;
      if (fonts.regular.widthOfTextAtSize(test, size) > maxW) {
        flush();
        buf = ch;
      } else {
        buf = test;
      }
    }
    if (buf) flush();
    return y;
  }

  /**
   * 표준근로계약서 PDF — 고용노동부 일용직 표준근로계약서 항목 + 양측 서명.
   */
  async renderLaborContractPdf(data: LaborContractPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    const fonts = await this.embedFonts(pdf);
    let page: PDFPage = pdf.addPage(A4);
    const W = page.getWidth();
    const H = page.getHeight();
    const contentW = W - 2 * MARGIN;

    let y = this.drawHeader(page, fonts, data.title, null, [
      `상태  ${data.statusLabel}`,
    ]);

    const ensureSpace = (need: number) => {
      if (y < MARGIN + need) {
        page = pdf.addPage(A4);
        y = H - MARGIN;
      }
    };
    const wrapped = (
      s: string,
      x: number,
      size: number,
      maxW: number,
      color = INK,
    ) => {
      let buf = '';
      const flush = () => {
        ensureSpace(40);
        page.drawText(buf, { x, y, size, font: fonts.regular, color });
        y -= size + 6;
        buf = '';
      };
      for (const ch of s) {
        if (ch === '\n') {
          flush();
          continue;
        }
        const test = buf + ch;
        if (fonts.regular.widthOfTextAtSize(test, size) > maxW) {
          flush();
          buf = ch;
        } else {
          buf = test;
        }
      }
      if (buf) flush();
    };

    // 당사자
    y = this.sectionTitle(page, fonts, '계약 당사자', y);
    const bizLine = [
      `사업주(갑)  ${data.businessName}`,
      data.businessNumber ? `사업자번호 ${data.businessNumber}` : null,
    ]
      .filter(Boolean)
      .join('    ');
    wrapped(bizLine, MARGIN, 11, contentW);
    if (data.businessAddress) {
      wrapped(`주소  ${data.businessAddress}`, MARGIN, 10, contentW, MUTED);
    }
    const workerLine = [
      `근로자(을)  ${data.workerName}`,
      data.workerPhone ? `연락처 ${data.workerPhone}` : null,
    ]
      .filter(Boolean)
      .join('    ');
    wrapped(workerLine, MARGIN, 11, contentW);
    y -= 10;

    // 조항 (라벨 | 값)
    y = this.sectionTitle(page, fonts, '계약 내용', y);
    const rows: Array<[string, string]> = [
      [
        '1. 근로계약기간',
        data.endDate
          ? `${data.startDate} ~ ${data.endDate}`
          : `${data.startDate} 부터 (기간의 정함 없음/일 단위)`,
      ],
      ['2. 근무 장소', data.workplace],
      ['3. 업무 내용', data.jobDescription],
      [
        '4. 근로시간',
        `${data.timeRange}${data.breakTime ? ` (휴게 ${data.breakTime})` : ''}`,
      ],
      ['5. 임금', `${data.wageTypeLabel} ${this.krw(data.wageAmount)}`],
      ['6. 임금 지급일', data.payday],
      ['7. 지급 방법', data.payMethod],
    ];
    const labelX = MARGIN;
    const valueX = MARGIN + 120;
    const valueMaxW = contentW - 120;
    for (const [label, value] of rows) {
      ensureSpace(48);
      const yStart = y;
      page.drawText(label, {
        x: labelX,
        y,
        size: 11,
        font: fonts.bold,
        color: MUTED,
      });
      wrapped(value, valueX, 11, valueMaxW);
      if (yStart - y < 24) y = yStart - 24;
      page.drawLine({
        start: { x: MARGIN, y: y + 8 },
        end: { x: W - MARGIN, y: y + 8 },
        thickness: 0.4,
        color: BORDER,
      });
    }
    y -= 10;

    // 8. 수당
    ensureSpace(60);
    page.drawText('8. 수당', {
      x: MARGIN,
      y,
      size: 11,
      font: fonts.bold,
      color: MUTED,
    });
    y -= 18;
    const allowanceNote = [
      data.weeklyHolidayAllowance
        ? '주휴수당: 1주 소정근로일 개근 시 주휴수당을 지급한다.'
        : '주휴수당: 해당 없음(일용/단시간 등).',
      data.overtimeAllowance
        ? '연장·야간·휴일근로 시 근로기준법에 따라 통상임금의 50%를 가산하여 지급한다.'
        : '연장·야간·휴일 가산수당: 별도 정하지 않음.',
    ].join('\n');
    wrapped(allowanceNote, MARGIN + 12, 10, contentW - 12, MUTED);
    y -= 8;

    // 9. 4대보험
    ensureSpace(40);
    page.drawText('9. 사회보험 적용', {
      x: MARGIN,
      y,
      size: 11,
      font: fonts.bold,
      color: MUTED,
    });
    y -= 18;
    const si = data.socialInsurance ?? {};
    const check = (b?: boolean) => (b ? '[적용]' : '[미적용]');
    const siText = [
      `고용보험 ${check(si.employment)}`,
      `건강보험 ${check(si.health)}`,
      `국민연금 ${check(si.pension)}`,
      `산재보험 ${check(si.industrialAccident)}`,
    ].join('    ');
    wrapped(siText, MARGIN + 12, 10, contentW - 12);
    y -= 8;

    // 10. 특약사항
    if (data.specialTerms) {
      ensureSpace(40);
      page.drawText('10. 특약사항', {
        x: MARGIN,
        y,
        size: 11,
        font: fonts.bold,
        color: MUTED,
      });
      y -= 18;
      wrapped(data.specialTerms, MARGIN + 12, 10, contentW - 12);
      y -= 8;
    }

    // 정본 안내
    ensureSpace(30);
    wrapped(
      '※ 본 계약서의 정본은 한국어본입니다. 번역본은 이해를 돕기 위한 참고용입니다.',
      MARGIN,
      9,
      contentW,
      MUTED,
    );
    y -= 6;

    // 서명 도장 박스 2개
    ensureSpace(170);
    const boxTop = Math.max(y - 10, MARGIN + 140);
    const halfW = (contentW - 24) / 2;
    await this.drawSignatureStamp(
      pdf,
      page,
      fonts,
      MARGIN,
      boxTop,
      halfW,
      '사업주(갑)',
      data.employerSignerName,
      data.employerSignedAt,
      data.employerSignPng,
    );
    await this.drawSignatureStamp(
      pdf,
      page,
      fonts,
      MARGIN + halfW + 24,
      boxTop,
      halfW,
      '근로자(을)',
      data.workerSignerName,
      data.workerSignedAt,
      data.workerSignPng,
    );

    this.stampFooters(pdf, fonts);
    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /** 월간 명세서 PDF (상대별 소계 + 총계 표). */
  async renderStatementPdf(data: StatementPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    const fonts = await this.embedFonts(pdf);
    let page: PDFPage = pdf.addPage(A4);
    const W = page.getWidth();
    const H = page.getHeight();
    const contentW = W - 2 * MARGIN;

    let y = this.drawHeader(
      page,
      fonts,
      data.title,
      `${data.month}  ·  작업자 ${data.workerName}`,
    );

    y = this.sectionTitle(page, fonts, '상대별 청구·수금 현황', y);

    const cols = {
      company: MARGIN + 12,
      days: MARGIN + 202,
      amount: MARGIN + 307,
      paid: MARGIN + 402,
      out: W - MARGIN - 12,
    };
    const right = (
      s: string,
      xr: number,
      yy: number,
      size: number,
      color = INK,
      bold = false,
    ) => {
      const f = bold ? fonts.bold : fonts.regular;
      page.drawText(s, {
        x: xr - f.widthOfTextAtSize(s, size),
        y: yy,
        size,
        font: f,
        color,
      });
    };

    const drawHead = () => {
      page.drawRectangle({
        x: MARGIN,
        y: y - 6,
        width: contentW,
        height: 20,
        color: PAPER,
      });
      const hy = y - 2;
      page.drawText('상대(회사)', {
        x: cols.company,
        y: hy,
        size: 10,
        font: fonts.bold,
        color: MUTED,
      });
      right('일수', cols.days, hy, 10, MUTED, true);
      right('청구액', cols.amount, hy, 10, MUTED, true);
      right('입금', cols.paid, hy, 10, MUTED, true);
      right('미수', cols.out, hy, 10, MUTED, true);
      y -= 24;
    };
    drawHead();

    const rowH = 22;
    let i = 0;
    for (const g of data.groups) {
      if (y < MARGIN + 90) {
        page = pdf.addPage(A4);
        y = H - MARGIN;
        drawHead();
      }
      const rowBot = y - rowH + 6;
      if (i % 2 === 1) {
        page.drawRectangle({
          x: MARGIN,
          y: rowBot,
          width: contentW,
          height: rowH,
          color: PAPER,
        });
      }
      const name = this.clip(
        fonts.regular,
        g.companyName || '(미지정)',
        11,
        170,
      );
      page.drawText(name, {
        x: cols.company,
        y,
        size: 11,
        font: fonts.regular,
        color: INK,
      });
      right(String(g.days), cols.days, y, 11);
      right(this.krw(g.subtotal), cols.amount, y, 11);
      right(this.krw(g.paid), cols.paid, y, 11, g.paid > 0 ? GREEN : INK);
      right(
        this.krw(g.outstanding),
        cols.out,
        y,
        11,
        g.outstanding > 0 ? ORANGE_DARK : INK,
      );
      page.drawLine({
        start: { x: MARGIN, y: y - 7 },
        end: { x: W - MARGIN, y: y - 7 },
        thickness: 0.4,
        color: BORDER,
      });
      y -= rowH;
      i += 1;
    }

    // 총계 강조 밴드
    y -= 4;
    page.drawRectangle({
      x: MARGIN,
      y: y - 24,
      width: contentW,
      height: 28,
      color: TOTAL_FILL,
      borderColor: ORANGE,
      borderWidth: 1.2,
    });
    const ty = y - 15;
    page.drawText('총계', {
      x: cols.company,
      y: ty,
      size: 12,
      font: fonts.bold,
      color: INK,
    });
    right(String(data.totalDays), cols.days, ty, 12, INK, true);
    right(this.krw(data.totalAmount), cols.amount, ty, 12, INK, true);
    right(this.krw(data.totalPaid), cols.paid, ty, 12, GREEN, true);
    right(this.krw(data.totalOutstanding), cols.out, ty, 12, ORANGE_DARK, true);

    this.stampFooters(pdf, fonts);
    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /** 연간(기간별) 소득 리포트 PDF — 총계 + 월별 추이 표 + 상대별 표 + 종소세 안내 (P2d). */
  async renderIncomeReportPdf(data: IncomeReportPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    const fonts = await this.embedFonts(pdf);
    let page: PDFPage = pdf.addPage(A4);
    const W = page.getWidth();
    const H = page.getHeight();
    const contentW = W - 2 * MARGIN;

    let y = this.drawHeader(
      page,
      fonts,
      data.title,
      `${data.periodLabel}  ·  작업자 ${data.workerName}`,
    );

    const right = (
      s: string,
      xr: number,
      yy: number,
      size: number,
      color = INK,
      bold = false,
    ) => {
      const f = bold ? fonts.bold : fonts.regular;
      page.drawText(s, {
        x: xr - f.widthOfTextAtSize(s, size),
        y: yy,
        size,
        font: f,
        color,
      });
    };
    const pageBreak = (need: number) => {
      if (y < MARGIN + need) {
        page = pdf.addPage(A4);
        y = H - MARGIN;
      }
    };

    // 총계 요약
    y = this.sectionTitle(page, fonts, '총계', y);
    const summaryRows: Array<[string, string]> = [
      ['총 청구액', this.krw(data.totals.totalBilled)],
      ['총 입금', this.krw(data.totals.totalPaid)],
      ['총 미수', this.krw(data.totals.totalOutstanding)],
      ['총 일한 날', `${data.totals.totalDays}일`],
      ['총 공수', `${data.totals.totalGongsu}공수`],
    ];
    if (data.totals.teamPayout > 0) {
      summaryRows.push([
        '팀 지급분(팀원 몫)',
        this.krw(data.totals.teamPayout),
      ]);
      summaryRows.push([
        '순소득 참고(청구-지급분)',
        this.krw(data.totals.netBilled),
      ]);
    }
    for (const [label, value] of summaryRows) {
      page.drawText(label, {
        x: MARGIN,
        y,
        size: 11,
        font: fonts.regular,
        color: MUTED,
      });
      const color = label.includes('미수')
        ? ORANGE_DARK
        : label.includes('입금')
          ? GREEN
          : INK;
      right(value, W - MARGIN, y, 11, color, label.includes('청구'));
      y -= 18;
    }
    y -= 12;

    // 월별 추이 표
    pageBreak(120);
    y = this.sectionTitle(page, fonts, '월별 추이', y);
    const mcol = {
      month: MARGIN + 4,
      billed: MARGIN + 190,
      paid: MARGIN + 300,
      out: MARGIN + 410,
      days: W - MARGIN,
    };
    page.drawRectangle({
      x: MARGIN,
      y: y - 6,
      width: contentW,
      height: 20,
      color: PAPER,
    });
    let hy = y - 2;
    page.drawText('월', {
      x: mcol.month,
      y: hy,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    right('청구액', mcol.billed, hy, 10, MUTED, true);
    right('입금', mcol.paid, hy, 10, MUTED, true);
    right('미수', mcol.out, hy, 10, MUTED, true);
    right('일수/공수', mcol.days, hy, 10, MUTED, true);
    y -= 24;
    for (const m of data.monthly) {
      pageBreak(30);
      page.drawText(m.month, {
        x: mcol.month,
        y,
        size: 10,
        font: fonts.regular,
        color: INK,
      });
      right(this.krw(m.billed), mcol.billed, y, 10);
      right(this.krw(m.paid), mcol.paid, y, 10, m.paid > 0 ? GREEN : INK);
      right(
        this.krw(m.outstanding),
        mcol.out,
        y,
        10,
        m.outstanding > 0 ? ORANGE_DARK : INK,
      );
      const dg =
        m.gongsu > 0
          ? `${m.daysWorked}일/${m.gongsu}공수`
          : `${m.daysWorked}일`;
      right(dg, mcol.days, y, 10, MUTED);
      page.drawLine({
        start: { x: MARGIN, y: y - 6 },
        end: { x: W - MARGIN, y: y - 6 },
        thickness: 0.3,
        color: BORDER,
      });
      y -= 18;
    }
    y -= 14;

    // 상대별 표
    pageBreak(100);
    y = this.sectionTitle(page, fonts, '상대별 합계', y);
    const ccol = {
      name: MARGIN + 4,
      count: MARGIN + 220,
      total: MARGIN + 320,
      paid: MARGIN + 420,
      out: W - MARGIN,
    };
    page.drawRectangle({
      x: MARGIN,
      y: y - 6,
      width: contentW,
      height: 20,
      color: PAPER,
    });
    hy = y - 2;
    page.drawText('상대(회사)', {
      x: ccol.name,
      y: hy,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    right('건수', ccol.count, hy, 10, MUTED, true);
    right('총액', ccol.total, hy, 10, MUTED, true);
    right('입금', ccol.paid, hy, 10, MUTED, true);
    right('미수', ccol.out, hy, 10, MUTED, true);
    y -= 24;
    if (data.companies.length === 0) {
      page.drawText('기록 없음', {
        x: ccol.name,
        y,
        size: 10,
        font: fonts.regular,
        color: MUTED,
      });
      y -= 18;
    }
    for (const c of data.companies) {
      pageBreak(30);
      page.drawText(
        this.clip(fonts.regular, c.companyName || '(미지정)', 11, 200),
        {
          x: ccol.name,
          y,
          size: 11,
          font: fonts.regular,
          color: INK,
        },
      );
      right(`${c.count}건`, ccol.count, y, 10, MUTED);
      right(this.krw(c.total), ccol.total, y, 10);
      right(this.krw(c.paid), ccol.paid, y, 10, c.paid > 0 ? GREEN : INK);
      right(
        this.krw(c.outstanding),
        ccol.out,
        y,
        10,
        c.outstanding > 0 ? ORANGE_DARK : INK,
      );
      page.drawLine({
        start: { x: MARGIN, y: y - 6 },
        end: { x: W - MARGIN, y: y - 6 },
        thickness: 0.3,
        color: BORDER,
      });
      y -= 18;
    }
    y -= 16;

    // 종소세 안내
    pageBreak(120);
    y = this.sectionTitle(page, fonts, '종합소득세 안내', y);
    const noteMaxW = contentW - 12;
    for (const noteLine of data.taxNoteLines) {
      let buf = '';
      const flush = () => {
        pageBreak(24);
        page.drawText(`· ${buf}`, {
          x: MARGIN,
          y,
          size: 9,
          font: fonts.regular,
          color: MUTED,
        });
        y -= 14;
        buf = '';
      };
      for (const ch of noteLine) {
        const test = buf + ch;
        if (fonts.regular.widthOfTextAtSize(`· ${test}`, 9) > noteMaxW) {
          flush();
          buf = ch;
        } else {
          buf = test;
        }
      }
      if (buf) flush();
      y -= 2;
    }

    this.stampFooters(pdf, fonts);
    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /** 현장별 인건비 집계 PDF (P5a) — 현장별 표(작업자/팀 행) + 소계 + 총계. 발주처 제출용. */
  async renderSiteCostsPdf(data: SiteCostsPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    const fonts = await this.embedFonts(pdf);
    let page: PDFPage = pdf.addPage(A4);
    const W = page.getWidth();
    const H = page.getHeight();
    const contentW = W - 2 * MARGIN;

    let y = this.drawHeader(
      page,
      fonts,
      data.title,
      `사업장  ${data.businessName}`,
      [`기간  ${data.periodLabel}`],
    );

    const col = {
      name: MARGIN + 4,
      days: MARGIN + 270,
      gongsu: MARGIN + 360,
      amount: W - MARGIN,
    };
    const right = (
      s: string,
      xr: number,
      yy: number,
      size: number,
      color = INK,
      bold = false,
    ) => {
      const f = bold ? fonts.bold : fonts.regular;
      page.drawText(s, {
        x: xr - f.widthOfTextAtSize(s, size),
        y: yy,
        size,
        font: f,
        color,
      });
    };
    const pageBreak = (need: number) => {
      if (y < MARGIN + need) {
        page = pdf.addPage(A4);
        y = H - MARGIN;
      }
    };

    for (const s of data.sites) {
      pageBreak(100);
      y = this.sectionTitle(
        page,
        fonts,
        this.clip(fonts.bold, s.site, 12, 320),
        y,
      );
      // 열 헤더
      page.drawRectangle({
        x: MARGIN,
        y: y - 6,
        width: contentW,
        height: 18,
        color: PAPER,
      });
      const hy = y - 2;
      page.drawText('작업자/팀', {
        x: col.name,
        y: hy,
        size: 9,
        font: fonts.bold,
        color: MUTED,
      });
      right('일수', col.days, hy, 9, MUTED, true);
      right('공수', col.gongsu, hy, 9, MUTED, true);
      right('금액', col.amount, hy, 9, MUTED, true);
      y -= 22;
      for (const e of s.entries) {
        pageBreak(28);
        const label = e.isTeam
          ? `${e.workerName} (팀 ${e.teamMemberCount}명)`
          : e.workerName;
        page.drawText(
          this.clip(fonts.regular, label, 10, col.days - col.name - 10),
          {
            x: col.name,
            y,
            size: 10,
            font: fonts.regular,
            color: INK,
          },
        );
        right(String(e.days), col.days, y, 10);
        right(e.gongsu > 0 ? String(e.gongsu) : '-', col.gongsu, y, 10);
        right(this.krw(e.amount), col.amount, y, 10);
        page.drawLine({
          start: { x: MARGIN, y: y - 6 },
          end: { x: W - MARGIN, y: y - 6 },
          thickness: 0.3,
          color: BORDER,
        });
        y -= 18;
      }
      // 현장 소계
      page.drawRectangle({
        x: MARGIN,
        y: y - 12,
        width: contentW,
        height: 20,
        color: PAPER,
      });
      const sy = y - 6;
      page.drawText('소계', {
        x: col.name,
        y: sy,
        size: 10,
        font: fonts.bold,
        color: INK,
      });
      right(String(s.subtotalDays), col.days, sy, 10, INK, true);
      right(
        s.subtotalGongsu > 0 ? String(s.subtotalGongsu) : '-',
        col.gongsu,
        sy,
        10,
        INK,
        true,
      );
      right(this.krw(s.subtotalAmount), col.amount, sy, 11, INK, true);
      y -= 34;
    }

    if (data.sites.length === 0) {
      page.drawText('해당 기간 서명 완료된 확인서가 없습니다.', {
        x: MARGIN,
        y,
        size: 10,
        font: fonts.regular,
        color: MUTED,
      });
      y -= 20;
    }

    // 전체 총계 강조 박스
    pageBreak(60);
    page.drawRectangle({
      x: MARGIN,
      y: y - 24,
      width: contentW,
      height: 28,
      color: TOTAL_FILL,
      borderColor: ORANGE,
      borderWidth: 1.2,
    });
    const ty = y - 15;
    page.drawText('전체 총계', {
      x: col.name,
      y: ty,
      size: 12,
      font: fonts.bold,
      color: INK,
    });
    right(String(data.totalDays), col.days, ty, 12, INK, true);
    right(
      data.totalGongsu > 0 ? String(data.totalGongsu) : '-',
      col.gongsu,
      ty,
      12,
      INK,
      true,
    );
    right(this.krw(data.totalAmount), col.amount, ty, 13, ORANGE_DARK, true);
    y -= 40;

    pageBreak(24);
    page.drawText(
      '※ 작업자 성명은 개인정보 보호를 위해 일부 마스킹되어 있습니다.',
      {
        x: MARGIN,
        y,
        size: 8,
        font: fonts.regular,
        color: MUTED,
      },
    );

    this.stampFooters(pdf, fonts);
    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /** 안전관리 이행 리포트 PDF (유형별 건수 + 발송/확인 기록 표). */
  async renderSafetyReportPdf(data: SafetyReportPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    const fonts = await this.embedFonts(pdf);
    let page: PDFPage = pdf.addPage(A4);
    const W = page.getWidth();
    const H = page.getHeight();
    const contentW = W - 2 * MARGIN;

    let y = this.drawHeader(
      page,
      fonts,
      data.title,
      `${data.month}  ·  ${data.businessName}`,
      [`총 ${data.totalCount}건`],
    );

    const right = (
      s: string,
      xr: number,
      yy: number,
      size: number,
      color = INK,
      bold = false,
    ) => {
      const f = bold ? fonts.bold : fonts.regular;
      page.drawText(s, {
        x: xr - f.widthOfTextAtSize(s, size),
        y: yy,
        size,
        font: f,
        color,
      });
    };
    const pageBreak = (need: number) => {
      if (y < MARGIN + need) {
        page = pdf.addPage(A4);
        y = H - MARGIN;
      }
    };

    // 유형별 건수
    y = this.sectionTitle(page, fonts, '유형별 건수', y);
    if (data.byType.length === 0) {
      page.drawText('기록 없음', {
        x: MARGIN,
        y,
        size: 10,
        font: fonts.regular,
        color: MUTED,
      });
      y -= 18;
    }
    for (const b of data.byType) {
      page.drawText(b.typeLabel, {
        x: MARGIN + 4,
        y,
        size: 11,
        font: fonts.regular,
        color: INK,
      });
      right(`${b.count}건`, W - MARGIN, y, 11, INK, true);
      page.drawLine({
        start: { x: MARGIN, y: y - 6 },
        end: { x: W - MARGIN, y: y - 6 },
        thickness: 0.3,
        color: BORDER,
      });
      y -= 20;
    }
    y -= 12;

    // TBM
    if (data.tbm && data.tbm.length > 0) {
      pageBreak(90);
      y = this.sectionTitle(
        page,
        fonts,
        'TBM(안전점검회의)',
        y,
        `총 ${data.tbm.length}회`,
      );
      const tcol = {
        date: MARGIN + 4,
        site: MARGIN + 92,
        hazards: MARGIN + 220,
        att: W - MARGIN,
      };
      page.drawRectangle({
        x: MARGIN,
        y: y - 6,
        width: contentW,
        height: 18,
        color: PAPER,
      });
      const hy = y - 2;
      page.drawText('일자', {
        x: tcol.date,
        y: hy,
        size: 10,
        font: fonts.bold,
        color: MUTED,
      });
      page.drawText('현장', {
        x: tcol.site,
        y: hy,
        size: 10,
        font: fonts.bold,
        color: MUTED,
      });
      page.drawText('위험요인', {
        x: tcol.hazards,
        y: hy,
        size: 10,
        font: fonts.bold,
        color: MUTED,
      });
      right('참석/확인', tcol.att, hy, 10, MUTED, true);
      y -= 22;
      for (const t of data.tbm) {
        pageBreak(30);
        page.drawText(t.date, {
          x: tcol.date,
          y,
          size: 10,
          font: fonts.regular,
          color: INK,
        });
        page.drawText(
          this.clip(fonts.regular, t.site, 10, tcol.hazards - tcol.site - 8),
          {
            x: tcol.site,
            y,
            size: 10,
            font: fonts.regular,
            color: INK,
          },
        );
        page.drawText(
          this.clip(
            fonts.regular,
            t.hazards || '-',
            10,
            tcol.att - tcol.hazards - 60,
          ),
          {
            x: tcol.hazards,
            y,
            size: 10,
            font: fonts.regular,
            color: MUTED,
          },
        );
        right(`${t.attendeeCount}/${t.ackCount}`, tcol.att, y, 10, INK, true);
        page.drawLine({
          start: { x: MARGIN, y: y - 6 },
          end: { x: W - MARGIN, y: y - 6 },
          thickness: 0.3,
          color: BORDER,
        });
        y -= 20;
      }
      y -= 12;
    }

    // 발송·확인 기록
    pageBreak(70);
    y = this.sectionTitle(page, fonts, '발송 · 확인 기록', y);
    const cols = {
      date: MARGIN + 4,
      type: MARGIN + 116,
      target: MARGIN + 256,
      ack: MARGIN + 366,
    };
    page.drawRectangle({
      x: MARGIN,
      y: y - 6,
      width: contentW,
      height: 18,
      color: PAPER,
    });
    const hy = y - 2;
    page.drawText('일자', {
      x: cols.date,
      y: hy,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    page.drawText('유형', {
      x: cols.type,
      y: hy,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    page.drawText('대상', {
      x: cols.target,
      y: hy,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    page.drawText('확인시각', {
      x: cols.ack,
      y: hy,
      size: 10,
      font: fonts.bold,
      color: MUTED,
    });
    y -= 22;
    let i = 0;
    for (const r of data.rows) {
      if (y < MARGIN + 50) {
        page = pdf.addPage(A4);
        y = H - MARGIN;
      }
      if (i % 2 === 1) {
        page.drawRectangle({
          x: MARGIN,
          y: y - 6,
          width: contentW,
          height: 18,
          color: PAPER,
        });
      }
      page.drawText(r.date, {
        x: cols.date,
        y,
        size: 10,
        font: fonts.regular,
        color: INK,
      });
      page.drawText(
        this.clip(fonts.regular, r.typeLabel, 10, cols.target - cols.type - 8),
        {
          x: cols.type,
          y,
          size: 10,
          font: fonts.regular,
          color: INK,
        },
      );
      page.drawText(
        this.clip(fonts.regular, r.targetName, 10, cols.ack - cols.target - 8),
        {
          x: cols.target,
          y,
          size: 10,
          font: fonts.regular,
          color: INK,
        },
      );
      page.drawText(r.ackAt ?? '-', {
        x: cols.ack,
        y,
        size: 10,
        font: fonts.regular,
        color: r.ackAt ? GREEN : MUTED,
      });
      y -= 18;
      i += 1;
    }

    this.stampFooters(pdf, fonts);
    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }
}
