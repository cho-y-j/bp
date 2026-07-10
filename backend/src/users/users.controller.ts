import { Body, Controller, Get, Patch } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UsersService } from './users.service';
import { UpdateMeDto } from './dto/update-me.dto';

@Controller()
export class UsersController {
  constructor(private readonly users: UsersService) {}

  // GET /me — 내 프로필 조회 (사업장 보유 여부 포함)
  @Get('me')
  getMe(@CurrentUser('userId') userId: string) {
    return this.users.getMe(userId);
  }

  // PATCH /me — 이름/업종태그/전화검색 동의 수정
  @Patch('me')
  updateMe(@CurrentUser('userId') userId: string, @Body() dto: UpdateMeDto) {
    return this.users.updateMe(userId, dto);
  }
}
