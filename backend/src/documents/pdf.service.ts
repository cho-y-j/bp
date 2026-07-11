import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { PDFDocument, PDFPage, rgb } from 'pdf-lib';
import fontkit from '@pdf-lib/fontkit';
import sharp from 'sharp';
import heicConvert from 'heic-convert';
import * as path from 'path';
import { promises as fs } from 'fs';
import { AppException } from '../common/errors';
import type {
  ConfirmationPdfData,
  LaborContractPdfData,
  SafetyReportPdfData,
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
  //  - 시스템 폰트를 backend/assets/fonts 에 복사해 로컬 임베드(외부 다운로드 불가).
  //  - fontkit 등록 + subset:true 로 사용 글리프만 서브셋(용량 최소화).
  // ==========================================================================
  private fontBytesCache: Buffer | null = null;

  private async loadFontBytes(): Promise<Buffer> {
    if (this.fontBytesCache) return this.fontBytesCache;
    // dist 빌드/소스 실행 모두에서 찾도록 후보 경로 탐색
    const candidates = [
      path.resolve(__dirname, '../../assets/fonts/NanumGothic-Regular.ttf'),
      path.resolve(process.cwd(), 'assets/fonts/NanumGothic-Regular.ttf'),
    ];
    for (const p of candidates) {
      try {
        const bytes = await fs.readFile(p);
        this.fontBytesCache = bytes;
        return bytes;
      } catch {
        // 다음 후보
      }
    }
    throw new AppException(
      'FONT_NOT_FOUND',
      '한글 폰트 파일을 찾을 수 없습니다 (assets/fonts).',
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }

  private krw(n: number): string {
    return `${Math.round(n).toLocaleString('ko-KR')}원`;
  }

  /** 작업확인서 PDF (종이 확인서 레이아웃). 서명 이미지가 있으면 서명란에 삽입. */
  async renderConfirmationPdf(data: ConfirmationPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    pdf.registerFontkit(fontkit);
    const fontBytes = await this.loadFontBytes();
    const font = await pdf.embedFont(fontBytes, { subset: true });

    const page = pdf.addPage([595.28, 841.89]); // A4 pt
    const { width, height } = page.getSize();
    const margin = 48;
    let y = height - margin;

    const black = rgb(0.1, 0.1, 0.1);
    const gray = rgb(0.45, 0.45, 0.45);
    const line = rgb(0.8, 0.8, 0.8);

    const text = (
      s: string,
      x: number,
      yy: number,
      size: number,
      color = black,
    ) => page.drawText(s ?? '', { x, y: yy, size, font, color });

    // 제목
    const titleSize = 22;
    const titleWidth = font.widthOfTextAtSize(data.title, titleSize);
    text(data.title, (width - titleWidth) / 2, y, titleSize);
    y -= 14;
    text(`상태: ${data.statusLabel}`, width - margin - 90, y, 9, gray);
    y -= 20;
    page.drawLine({
      start: { x: margin, y },
      end: { x: width - margin, y },
      thickness: 1.2,
      color: black,
    });
    y -= 24;

    // 필드 표 (라벨 | 값)
    const rows: Array<[string, string]> = [
      ['작성일', data.date],
      ['현장/장소', data.site],
      [
        '지시자(회사)',
        data.companyName + (data.contact ? ` (${data.contact})` : ''),
      ],
      ['작업자', data.workerName],
      ['작업 내용', data.workContent],
      ['작업 시간', data.timeRange],
      ['단가 유형', data.rateTypeLabel],
    ];
    const labelX = margin;
    const valueX = margin + 110;
    const rowH = 22;
    for (const [label, value] of rows) {
      text(label, labelX, y, 11, gray);
      // 값이 길면 자름(간단 처리)
      const v = value ?? '';
      const maxW = width - margin - valueX;
      let shown = v;
      while (font.widthOfTextAtSize(shown, 11) > maxW && shown.length > 1) {
        shown = shown.slice(0, -2);
      }
      if (shown !== v) shown = shown.slice(0, -1) + '…';
      text(shown, valueX, y, 11);
      y -= rowH;
      page.drawLine({
        start: { x: margin, y: y + rowH - 6 },
        end: { x: width - margin, y: y + rowH - 6 },
        thickness: 0.5,
        color: line,
      });
    }

    // 장비 섹션(옵션)
    if (data.equipment) {
      y -= 8;
      text('■ 장비', margin, y, 12);
      y -= rowH;
      const e = data.equipment;
      const parts = [
        e.name ? `장비명: ${e.name}` : null,
        e.vehicleNumber ? `차량번호: ${e.vehicleNumber}` : null,
        e.spec ? `규격: ${e.spec}` : null,
        `유도원: ${e.guide ? '있음' : '없음'}`,
      ].filter(Boolean) as string[];
      text(parts.join('   '), margin, y, 10, gray);
      y -= rowH;
    }

    // 팀(반장) 명단 표 — 팀 확인서면 이름/공수/단가/금액 렌더
    if (data.teamEntries && data.teamEntries.length > 0) {
      y -= 8;
      text('■ 팀 명단', margin, y, 12);
      y -= 20;
      const tcol = {
        name: margin,
        gongsu: margin + 220,
        rate: margin + 320,
        amount: width - margin,
      };
      text('이름', tcol.name, y, 10, gray);
      const gHdr = '공수';
      text(gHdr, tcol.gongsu - font.widthOfTextAtSize(gHdr, 10), y, 10, gray);
      const rHdr = '단가';
      text(rHdr, tcol.rate - font.widthOfTextAtSize(rHdr, 10), y, 10, gray);
      const aHdr = '금액';
      text(aHdr, tcol.amount - font.widthOfTextAtSize(aHdr, 10), y, 10, gray);
      y -= 6;
      page.drawLine({
        start: { x: margin, y },
        end: { x: width - margin, y },
        thickness: 0.6,
        color: line,
      });
      y -= 18;
      for (const m of data.teamEntries) {
        text(m.name, tcol.name, y, 11);
        const g = `${m.quantity}공수`;
        text(g, tcol.gongsu - font.widthOfTextAtSize(g, 10), y, 10, gray);
        const r = m.rate.toLocaleString('ko-KR');
        text(r, tcol.rate - font.widthOfTextAtSize(r, 10), y, 10, gray);
        const a = this.krw(m.amount);
        text(a, tcol.amount - font.widthOfTextAtSize(a, 11), y, 11);
        y -= rowH;
      }
      page.drawLine({
        start: { x: margin, y: y + 8 },
        end: { x: width - margin, y: y + 8 },
        thickness: 0.6,
        color: line,
      });
      y -= 4;
    }

    // 금액 표
    y -= 8;
    text('■ 금액', margin, y, 12);
    y -= 20;
    const col = { item: margin, detail: margin + 150, amount: width - margin };
    text('항목', col.item, y, 10, gray);
    text('단가 × 수량', col.detail, y, 10, gray);
    const amtHdr = '금액';
    text(amtHdr, col.amount - font.widthOfTextAtSize(amtHdr, 10), y, 10, gray);
    y -= 6;
    page.drawLine({
      start: { x: margin, y },
      end: { x: width - margin, y },
      thickness: 0.6,
      color: line,
    });
    y -= 18;
    for (const li of data.lines) {
      text(li.label, col.item, y, 11);
      text(li.detail, col.detail, y, 10, gray);
      const a = this.krw(li.amount);
      text(a, col.amount - font.widthOfTextAtSize(a, 11), y, 11);
      y -= rowH;
    }
    // 팀 확인서는 항목 라인이 없으므로 팀 합계를 금액 표에 한 줄로 표기.
    if (
      data.teamEntries &&
      data.teamEntries.length > 0 &&
      data.lines.length === 0
    ) {
      text('팀 작업 합계', col.item, y, 11);
      text(`팀원 ${data.teamEntries.length}명`, col.detail, y, 10, gray);
      const a = this.krw(data.subtotal);
      text(a, col.amount - font.widthOfTextAtSize(a, 11), y, 11);
      y -= rowH;
    }
    page.drawLine({
      start: { x: margin, y: y + 8 },
      end: { x: width - margin, y: y + 8 },
      thickness: 0.6,
      color: line,
    });

    // 합계/부가세/총액
    const putRight = (
      label: string,
      value: string,
      size: number,
      bold = false,
    ) => {
      text(label, col.detail, y, size, gray);
      const c = bold ? black : black;
      text(value, col.amount - font.widthOfTextAtSize(value, size), y, size, c);
      y -= size + 8;
    };
    putRight('공급가 합계', this.krw(data.subtotal), 11);
    if (data.vatRate > 0) {
      putRight(
        `부가세 (${Math.round(data.vatRate * 100)}%)`,
        this.krw(data.vat),
        11,
      );
    }
    putRight('청구 합계', this.krw(data.total), 14, true);

    // 특이사항
    if (data.notes) {
      y -= 6;
      text('특이사항', margin, y, 11, gray);
      y -= 18;
      // 줄바꿈 간단 처리
      const maxW = width - 2 * margin;
      let buf = '';
      const flush = () => {
        if (buf) {
          text(buf, margin, y, 10);
          y -= 16;
          buf = '';
        }
      };
      for (const ch of data.notes) {
        const test = buf + ch;
        if (font.widthOfTextAtSize(test, 10) > maxW || ch === '\n') {
          flush();
          if (ch !== '\n') buf = ch;
        } else {
          buf = test;
        }
      }
      flush();
    }

    // 서명란 (하단)
    const sigY = margin + 90;
    page.drawLine({
      start: { x: margin, y: sigY + 70 },
      end: { x: width - margin, y: sigY + 70 },
      thickness: 0.5,
      color: line,
    });
    text('서명', margin, sigY + 50, 12, gray);
    if (data.signerName) {
      text(`서명자: ${data.signerName}`, margin, sigY + 28, 11);
      if (data.signedAt) {
        text(`서명일시: ${data.signedAt}`, margin, sigY + 10, 9, gray);
      }
    } else {
      text('(미서명)', margin, sigY + 28, 11, gray);
    }
    // 서명 이미지 박스
    const boxX = width - margin - 180;
    const boxW = 180;
    const boxH = 70;
    page.drawRectangle({
      x: boxX,
      y: sigY,
      width: boxW,
      height: boxH,
      borderColor: line,
      borderWidth: 1,
    });
    if (data.signImagePng) {
      try {
        const img = await pdf.embedPng(data.signImagePng);
        const scale = Math.min(
          (boxW - 12) / img.width,
          (boxH - 12) / img.height,
          1,
        );
        const w = img.width * scale;
        const h = img.height * scale;
        page.drawImage(img, {
          x: boxX + (boxW - w) / 2,
          y: sigY + (boxH - h) / 2,
          width: w,
          height: h,
        });
      } catch (e) {
        this.logger.warn(`서명 이미지 삽입 실패: ${(e as Error).message}`);
      }
    }
    text('(서명란)', boxX + 6, sigY + boxH + 4, 8, gray);

    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /**
   * 표준근로계약서 PDF — 고용노동부 일용직 표준근로계약서 항목 + 양측 서명.
   *  - 조항을 번호로 나열하고, 하단에 사업장/근로자 두 서명란을 둔다.
   *  - 정본 안내(한국어본이 정본) 문구를 하단에 표기한다.
   */
  async renderLaborContractPdf(data: LaborContractPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    pdf.registerFontkit(fontkit);
    const fontBytes = await this.loadFontBytes();
    const font = await pdf.embedFont(fontBytes, { subset: true });

    const A4: [number, number] = [595.28, 841.89];
    let page: PDFPage = pdf.addPage(A4);
    const { width, height } = page.getSize();
    const margin = 48;
    let y = height - margin;

    const black = rgb(0.1, 0.1, 0.1);
    const gray = rgb(0.45, 0.45, 0.45);
    const line = rgb(0.8, 0.8, 0.8);

    const text = (
      s: string,
      x: number,
      yy: number,
      size: number,
      color = black,
    ) => page.drawText(s ?? '', { x, y: yy, size, font, color });

    const ensureSpace = (need: number) => {
      if (y < margin + need) {
        page = pdf.addPage(A4);
        y = height - margin;
      }
    };

    // 여러 줄 래핑 렌더 (지정 폭 내에서 자동 줄바꿈)
    const wrapped = (
      s: string,
      x: number,
      size: number,
      maxW: number,
      color = black,
    ) => {
      let buf = '';
      const flush = () => {
        ensureSpace(40);
        text(buf, x, y, size, color);
        y -= size + 6;
        buf = '';
      };
      for (const ch of s) {
        if (ch === '\n') {
          flush();
          continue;
        }
        const test = buf + ch;
        if (font.widthOfTextAtSize(test, size) > maxW) {
          flush();
          buf = ch;
        } else {
          buf = test;
        }
      }
      if (buf) flush();
    };

    // 제목
    const titleSize = 22;
    const titleWidth = font.widthOfTextAtSize(data.title, titleSize);
    text(data.title, (width - titleWidth) / 2, y, titleSize);
    y -= 14;
    text(`상태: ${data.statusLabel}`, width - margin - 90, y, 9, gray);
    y -= 18;
    page.drawLine({
      start: { x: margin, y },
      end: { x: width - margin, y },
      thickness: 1.2,
      color: black,
    });
    y -= 22;

    // 당사자
    text('■ 계약 당사자', margin, y, 12);
    y -= 20;
    const bizLine = [
      `사업주(갑): ${data.businessName}`,
      data.businessNumber ? `사업자번호 ${data.businessNumber}` : null,
    ]
      .filter(Boolean)
      .join('   ');
    wrapped(bizLine, margin, 11, width - 2 * margin);
    if (data.businessAddress) {
      wrapped(
        `주소: ${data.businessAddress}`,
        margin,
        10,
        width - 2 * margin,
        gray,
      );
    }
    const workerLine = [
      `근로자(을): ${data.workerName}`,
      data.workerPhone ? `연락처 ${data.workerPhone}` : null,
    ]
      .filter(Boolean)
      .join('   ');
    wrapped(workerLine, margin, 11, width - 2 * margin);
    y -= 6;

    // 조항 표 (라벨 | 값)
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
    const labelX = margin;
    const valueX = margin + 120;
    const valueMaxW = width - margin - valueX;
    text('■ 계약 내용', margin, y, 12);
    y -= 20;
    for (const [label, value] of rows) {
      ensureSpace(48);
      const yStart = y;
      text(label, labelX, y, 11, gray);
      wrapped(value, valueX, 11, valueMaxW);
      // 값이 한 줄이면 y 가 한 줄만 줄었을 것. 라벨-값 정렬 유지 위해 최소 rowH 확보.
      if (yStart - y < 22) y = yStart - 22;
      page.drawLine({
        start: { x: margin, y: y + 8 },
        end: { x: width - margin, y: y + 8 },
        thickness: 0.4,
        color: line,
      });
    }
    y -= 8;

    // 8. 주휴·연장수당 문구
    ensureSpace(60);
    text('8. 수당', margin, y, 11, gray);
    y -= 18;
    const allowanceNote = [
      data.weeklyHolidayAllowance
        ? '주휴수당: 1주 소정근로일 개근 시 주휴수당을 지급한다.'
        : '주휴수당: 해당 없음(일용/단시간 등).',
      data.overtimeAllowance
        ? '연장·야간·휴일근로 시 근로기준법에 따라 통상임금의 50%를 가산하여 지급한다.'
        : '연장·야간·휴일 가산수당: 별도 정하지 않음.',
    ].join('\n');
    wrapped(allowanceNote, margin + 12, 10, width - 2 * margin - 12, gray);
    y -= 6;

    // 9. 4대보험
    ensureSpace(40);
    text('9. 사회보험 적용', margin, y, 11, gray);
    y -= 18;
    const si = data.socialInsurance ?? {};
    const check = (b?: boolean) => (b ? '[적용]' : '[미적용]');
    const siText = [
      `고용보험 ${check(si.employment)}`,
      `건강보험 ${check(si.health)}`,
      `국민연금 ${check(si.pension)}`,
      `산재보험 ${check(si.industrialAccident)}`,
    ].join('   ');
    wrapped(siText, margin + 12, 10, width - 2 * margin - 12);
    y -= 6;

    // 10. 특약사항
    if (data.specialTerms) {
      ensureSpace(40);
      text('10. 특약사항', margin, y, 11, gray);
      y -= 18;
      wrapped(data.specialTerms, margin + 12, 10, width - 2 * margin - 12);
      y -= 6;
    }

    // 정본 안내 (한국어본이 정본)
    ensureSpace(30);
    y -= 6;
    wrapped(
      '※ 본 계약서의 정본은 한국어본입니다. 번역본은 이해를 돕기 위한 참고용입니다.',
      margin,
      9,
      width - 2 * margin,
      gray,
    );
    y -= 4;

    // 서명란 (사업장 / 근로자 2개 박스) — 페이지 하단에 배치
    ensureSpace(160);
    const boxTop = Math.max(y - 10, margin + 130);
    y = boxTop;
    page.drawLine({
      start: { x: margin, y: y + 6 },
      end: { x: width - margin, y: y + 6 },
      thickness: 0.6,
      color: line,
    });
    y -= 16;
    const halfW = (width - 2 * margin - 20) / 2;
    const boxH = 70;
    const drawSignBox = async (
      x: number,
      label: string,
      signerName?: string | null,
      signedAt?: string | null,
      png?: Buffer | null,
    ) => {
      text(label, x, y, 11, gray);
      const boxY = y - boxH - 6;
      page.drawRectangle({
        x,
        y: boxY,
        width: halfW,
        height: boxH,
        borderColor: line,
        borderWidth: 1,
      });
      if (png) {
        try {
          const img = await pdf.embedPng(png);
          const scale = Math.min(
            (halfW - 12) / img.width,
            (boxH - 12) / img.height,
            1,
          );
          const w = img.width * scale;
          const h = img.height * scale;
          page.drawImage(img, {
            x: x + (halfW - w) / 2,
            y: boxY + (boxH - h) / 2,
            width: w,
            height: h,
          });
        } catch (e) {
          this.logger.warn(`서명 이미지 삽입 실패: ${(e as Error).message}`);
        }
      } else {
        text('(미서명)', x + 8, boxY + boxH / 2, 10, gray);
      }
      text(
        signerName ? `성명: ${signerName}` : '성명: ____________',
        x,
        boxY - 14,
        10,
      );
      if (signedAt) text(`서명일시: ${signedAt}`, x, boxY - 28, 8, gray);
    };
    await drawSignBox(
      margin,
      '사업주(갑)',
      data.employerSignerName,
      data.employerSignedAt,
      data.employerSignPng,
    );
    await drawSignBox(
      margin + halfW + 20,
      '근로자(을)',
      data.workerSignerName,
      data.workerSignedAt,
      data.workerSignPng,
    );

    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /** 월간 명세서 PDF (상대별 소계 + 총계 표). */
  async renderStatementPdf(data: StatementPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    pdf.registerFontkit(fontkit);
    const fontBytes = await this.loadFontBytes();
    const font = await pdf.embedFont(fontBytes, { subset: true });

    let page: PDFPage = pdf.addPage([595.28, 841.89]);
    const { width, height } = page.getSize();
    const margin = 48;
    let y = height - margin;
    const black = rgb(0.1, 0.1, 0.1);
    const gray = rgb(0.45, 0.45, 0.45);
    const line = rgb(0.8, 0.8, 0.8);

    const text = (
      s: string,
      x: number,
      yy: number,
      size: number,
      color = black,
    ) => page.drawText(s ?? '', { x, y: yy, size, font, color });
    const rightText = (
      s: string,
      xRight: number,
      yy: number,
      size: number,
      color = black,
    ) => text(s, xRight - font.widthOfTextAtSize(s, size), yy, size, color);

    const titleSize = 20;
    const t = `${data.title} (${data.month})`;
    text(t, (width - font.widthOfTextAtSize(t, titleSize)) / 2, y, titleSize);
    y -= 18;
    text(`작업자: ${data.workerName}`, margin, y, 10, gray);
    y -= 16;
    page.drawLine({
      start: { x: margin, y },
      end: { x: width - margin, y },
      thickness: 1,
      color: black,
    });
    y -= 22;

    // 표 헤더
    const cols = {
      company: margin,
      days: margin + 240,
      amount: margin + 320,
      paid: margin + 420,
      out: width - margin,
    };
    text('상대(회사)', cols.company, y, 10, gray);
    rightText('일수', cols.days + 30, y, 10, gray);
    rightText('청구액', cols.amount + 60, y, 10, gray);
    rightText('입금', cols.paid + 50, y, 10, gray);
    rightText('미수', cols.out, y, 10, gray);
    y -= 6;
    page.drawLine({
      start: { x: margin, y },
      end: { x: width - margin, y },
      thickness: 0.6,
      color: line,
    });
    y -= 18;

    const rowH = 20;
    const ensureSpace = () => {
      if (y < margin + 80) {
        page = pdf.addPage([595.28, 841.89]);
        y = height - margin;
      }
    };

    for (const g of data.groups) {
      ensureSpace();
      // 회사명 길면 자름
      let name = g.companyName || '(미지정)';
      const maxW = 220;
      while (font.widthOfTextAtSize(name, 11) > maxW && name.length > 1) {
        name = name.slice(0, -1);
      }
      text(name, cols.company, y, 11);
      rightText(String(g.days), cols.days + 30, y, 11);
      rightText(this.krw(g.subtotal), cols.amount + 60, y, 11);
      rightText(this.krw(g.paid), cols.paid + 50, y, 11);
      rightText(this.krw(g.outstanding), cols.out, y, 11);
      y -= rowH;
    }

    // 총계
    y -= 4;
    page.drawLine({
      start: { x: margin, y: y + 10 },
      end: { x: width - margin, y: y + 10 },
      thickness: 1,
      color: black,
    });
    text('총계', cols.company, y - 8, 12);
    rightText(String(data.totalDays), cols.days + 30, y - 8, 12);
    rightText(this.krw(data.totalAmount), cols.amount + 60, y - 8, 12);
    rightText(this.krw(data.totalPaid), cols.paid + 50, y - 8, 12);
    rightText(this.krw(data.totalOutstanding), cols.out, y - 8, 12);

    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }

  /** 안전관리 이행 리포트 PDF (유형별 건수 + 발송/확인 기록 표). */
  async renderSafetyReportPdf(data: SafetyReportPdfData): Promise<Buffer> {
    const pdf = await PDFDocument.create();
    pdf.registerFontkit(fontkit);
    const fontBytes = await this.loadFontBytes();
    const font = await pdf.embedFont(fontBytes, { subset: true });

    let page: PDFPage = pdf.addPage([595.28, 841.89]);
    const { width, height } = page.getSize();
    const margin = 48;
    let y = height - margin;
    const black = rgb(0.1, 0.1, 0.1);
    const gray = rgb(0.45, 0.45, 0.45);
    const line = rgb(0.8, 0.8, 0.8);

    const text = (
      s: string,
      x: number,
      yy: number,
      size: number,
      color = black,
    ) => page.drawText(s ?? '', { x, y: yy, size, font, color });

    const titleSize = 20;
    const t = `${data.title} (${data.month})`;
    text(t, (width - font.widthOfTextAtSize(t, titleSize)) / 2, y, titleSize);
    y -= 18;
    text(`사업장: ${data.businessName}`, margin, y, 10, gray);
    text(
      `총 ${data.totalCount}건`,
      width - margin - font.widthOfTextAtSize(`총 ${data.totalCount}건`, 10),
      y,
      10,
      gray,
    );
    y -= 16;
    page.drawLine({
      start: { x: margin, y },
      end: { x: width - margin, y },
      thickness: 1,
      color: black,
    });
    y -= 24;

    // 유형별 건수
    text('■ 유형별 건수', margin, y, 12);
    y -= 20;
    if (data.byType.length === 0) {
      text('기록 없음', margin, y, 10, gray);
      y -= 18;
    }
    for (const b of data.byType) {
      text(b.typeLabel, margin, y, 11);
      const c = `${b.count}건`;
      text(c, width - margin - font.widthOfTextAtSize(c, 11), y, 11);
      y -= 18;
    }
    y -= 10;

    const pageBreak = (need: number) => {
      if (y < margin + need) {
        page = pdf.addPage([595.28, 841.89]);
        y = height - margin;
      }
    };

    // TBM(안전점검회의) 월간 목록 (P2c)
    if (data.tbm && data.tbm.length > 0) {
      pageBreak(80);
      text('■ TBM(안전점검회의)', margin, y, 12);
      const tbmTotal = `총 ${data.tbm.length}회`;
      text(
        tbmTotal,
        width - margin - font.widthOfTextAtSize(tbmTotal, 10),
        y,
        10,
        gray,
      );
      y -= 20;
      const tcol = {
        date: margin,
        site: margin + 88,
        hazards: margin + 210,
        att: width - margin,
      };
      text('일자', tcol.date, y, 10, gray);
      text('현장', tcol.site, y, 10, gray);
      text('위험요인', tcol.hazards, y, 10, gray);
      const attHdr = '참석/확인';
      text(attHdr, tcol.att - font.widthOfTextAtSize(attHdr, 10), y, 10, gray);
      y -= 6;
      page.drawLine({
        start: { x: margin, y },
        end: { x: width - margin, y },
        thickness: 0.6,
        color: line,
      });
      y -= 16;
      const clip = (s: string, maxW: number, size: number): string => {
        let shown = s ?? '';
        while (
          font.widthOfTextAtSize(shown, size) > maxW &&
          shown.length > 1
        ) {
          shown = shown.slice(0, -1);
        }
        return shown !== (s ?? '') ? shown.slice(0, -1) + '…' : shown;
      };
      for (const t of data.tbm) {
        pageBreak(30);
        text(t.date, tcol.date, y, 10);
        text(clip(t.site, tcol.hazards - tcol.site - 8, 10), tcol.site, y, 10);
        text(
          clip(t.hazards || '-', tcol.att - tcol.hazards - 60, 10),
          tcol.hazards,
          y,
          10,
          gray,
        );
        const att = `${t.attendeeCount}/${t.ackCount}`;
        text(att, tcol.att - font.widthOfTextAtSize(att, 10), y, 10);
        y -= 18;
      }
      y -= 10;
    }

    // 발송/확인 기록 표
    pageBreak(60);
    text('■ 발송 · 확인 기록', margin, y, 12);
    y -= 20;
    const cols = {
      date: margin,
      type: margin + 110,
      target: margin + 250,
      ack: margin + 360,
    };
    text('일자', cols.date, y, 10, gray);
    text('유형', cols.type, y, 10, gray);
    text('대상', cols.target, y, 10, gray);
    text('확인시각', cols.ack, y, 10, gray);
    y -= 6;
    page.drawLine({
      start: { x: margin, y },
      end: { x: width - margin, y },
      thickness: 0.6,
      color: line,
    });
    y -= 16;

    const rowH = 18;
    for (const r of data.rows) {
      if (y < margin + 40) {
        page = pdf.addPage([595.28, 841.89]);
        y = height - margin;
      }
      text(r.date, cols.date, y, 10);
      text(r.typeLabel, cols.type, y, 10);
      text(r.targetName, cols.target, y, 10);
      text(r.ackAt ?? '-', cols.ack, y, 10, r.ackAt ? black : gray);
      y -= rowH;
    }

    const bytes = await pdf.save();
    return Buffer.from(bytes);
  }
}
