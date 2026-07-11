import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { BusinessesService } from './businesses.service';
import { ConnectionsService } from './connections.service';
import { CreateBusinessDto } from './dto/create-business.dto';
import { UpdateBusinessDto } from './dto/update-business.dto';
import { CreateConnectionDto } from './dto/create-connection.dto';

/** /businesses — 사업장 생성·검색·내 사업장 */
@Controller('businesses')
export class BusinessesController {
  constructor(private readonly businesses: BusinessesService) {}

  @Post()
  create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateBusinessDto,
  ) {
    return this.businesses.create(userId, dto);
  }

  @Get('search')
  search(@Query('q') q: string) {
    return this.businesses.search(q);
  }

  @Get('mine')
  getMine(@CurrentUser('userId') userId: string) {
    return this.businesses.getMine(userId);
  }

  @Patch('mine')
  updateMine(
    @CurrentUser('userId') userId: string,
    @Body() dto: UpdateBusinessDto,
  ) {
    return this.businesses.updateMine(userId, dto);
  }

  // GET /businesses/:id — 단건 조회(공개 정보 + 지급 평판 배지). 'search'/'mine' 뒤에 선언.
  @Get(':id')
  getById(@Param('id', ParseUUIDPipe) id: string) {
    return this.businesses.getById(id);
  }
}

/** /workers/search — 전화번호로 작업자 검색(동의자만, 이름 마스킹) */
@Controller('workers')
export class WorkersController {
  constructor(private readonly connections: ConnectionsService) {}

  @Get('search')
  search(@Query('phone') phone: string) {
    return this.connections.searchWorkers(phone);
  }
}

/** /connections — 연결 요청·수락·목록·해제 */
@Controller('connections')
export class ConnectionsController {
  constructor(private readonly connections: ConnectionsService) {}

  @Post()
  request(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateConnectionDto,
  ) {
    return this.connections.request(userId, dto);
  }

  @Post(':id/accept')
  accept(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.connections.accept(userId, id);
  }

  @Get()
  list(@CurrentUser('userId') userId: string) {
    return this.connections.list(userId);
  }

  @Delete(':id')
  remove(
    @CurrentUser('userId') userId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.connections.remove(userId, id);
  }
}
