import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { PartnersService } from './partners.service';
import { UpdatePartnerDto } from './dto/update-partner.dto';
import { CreatePartnerDto } from './dto/create-partner.dto';

/** 인증 필요 — 본인 거래처(확인서 수기 상대 자동 수집 + 연결 상대) 조회·보강. */
@Controller('partners')
export class PartnersController {
  constructor(private readonly partners: PartnersService) {}

  @Get()
  list(@CurrentUser('userId') userId: string) {
    return this.partners.list(userId);
  }

  /** 수동 추가 — 확인서를 쓴 적 없는 거래처 등록. (profileId,name) 중복 시 409. */
  @Post()
  create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreatePartnerDto,
  ) {
    return this.partners.create(userId, dto);
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
