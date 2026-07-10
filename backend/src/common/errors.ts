import { HttpException, HttpStatus } from '@nestjs/common';

/**
 * 도메인 에러: { code, message } 를 실어 던진다.
 * 전역 예외 필터가 이를 API-SPEC 규약 { error: { code, message } } 로 변환한다.
 */
export class AppException extends HttpException {
  constructor(code: string, message: string, status: HttpStatus) {
    super({ code, message }, status);
  }
}
