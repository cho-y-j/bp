import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { PartnersService } from './partners.service';
import { UpdatePartnerDto } from './dto/update-partner.dto';

/** 인증 필요 — 본인 거래처(확인서 수기 상대 자동 수집 + 연결 상대) 조회·보강. */
@Controller('partners')
export class PartnersController {
  constructor(private readonly partners: PartnersService) {}

  @Get()
  list(@CurrentUser('userId') userId: string) {
    return this.partners.list(userId);
  }

  @Patch(':id')
  patch(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePartnerDto,
  ) {
    return this.partners.patch(userId, id, dto);
  }

  @Delete(':id')
  remove(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.partners.remove(userId, id);
  }
}
