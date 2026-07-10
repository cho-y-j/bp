import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createReadStream, type ReadStream } from 'fs';
import { promises as fs } from 'fs';
import * as path from 'path';
import { AppException } from '../common/errors';

/**
 * 로컬 파일 저장소.
 *  - 저장 루트: UPLOAD_DIR (기본 ./uploads), 절대경로로 해석.
 *  - 서류 파일은 uploads/{profileId}/{documentId}/ 아래에 둔다.
 *  - DB 에는 루트 기준 상대경로만 저장한다(이식성).
 *  - 모든 경로 접근은 safeResolve 로 루트 밖 접근(경로 조작)을 차단한다.
 */
@Injectable()
export class FileStorageService {
  private readonly base: string;
  // uuid v4 형태만 디렉터리 세그먼트로 허용 (경로 조작 방지)
  private static readonly ID_RE = /^[0-9a-fA-F-]{36}$/;

  constructor(config: ConfigService) {
    this.base = path.resolve(config.get<string>('UPLOAD_DIR') ?? './uploads');
  }

  /** 루트 기준 상대경로를 검증하여 절대경로로 변환. 루트 밖이면 예외. */
  private safeResolve(relPath: string): string {
    const abs = path.resolve(this.base, relPath);
    const rel = path.relative(this.base, abs);
    if (rel === '' || rel.startsWith('..') || path.isAbsolute(rel)) {
      throw new AppException(
        'INVALID_PATH',
        '잘못된 파일 경로입니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    return abs;
  }

  private assertId(id: string): void {
    if (!FileStorageService.ID_RE.test(id)) {
      throw new AppException(
        'INVALID_PATH',
        '잘못된 식별자입니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  /** 서류 파일의 루트 기준 상대경로 키를 만든다. filename 은 서버가 정한 고정 이름만. */
  buildKey(profileId: string, documentId: string, filename: string): string {
    this.assertId(profileId);
    this.assertId(documentId);
    // filename 은 화이트리스트 고정값만 (외부 입력 파일명 사용 금지)
    if (!/^[a-zA-Z0-9._-]+$/.test(filename)) {
      throw new AppException(
        'INVALID_PATH',
        '잘못된 파일명입니다.',
        HttpStatus.BAD_REQUEST,
      );
    }
    return path.posix.join(profileId, documentId, filename);
  }

  absolutePath(relPath: string): string {
    return this.safeResolve(relPath);
  }

  async writeFile(relPath: string, data: Buffer): Promise<string> {
    const abs = this.safeResolve(relPath);
    await fs.mkdir(path.dirname(abs), { recursive: true });
    await fs.writeFile(abs, data);
    return relPath;
  }

  async readFile(relPath: string): Promise<Buffer> {
    return fs.readFile(this.safeResolve(relPath));
  }

  createReadStream(relPath: string): ReadStream {
    return createReadStream(this.safeResolve(relPath));
  }

  async fileExists(relPath: string): Promise<boolean> {
    try {
      await fs.access(this.safeResolve(relPath));
      return true;
    } catch {
      return false;
    }
  }

  /** 서류 디렉터리(원본+정규화본+마스킹본) 전체 삭제. */
  async removeDocumentDir(
    profileId: string,
    documentId: string,
  ): Promise<void> {
    this.assertId(profileId);
    this.assertId(documentId);
    const dir = this.safeResolve(path.posix.join(profileId, documentId));
    await fs.rm(dir, { recursive: true, force: true });
  }
}
