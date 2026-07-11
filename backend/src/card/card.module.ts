import { Module } from '@nestjs/common';
import { CardService } from './card.service';
import { CardController, PublicProfilesController } from './card.controller';

@Module({
  controllers: [CardController, PublicProfilesController],
  providers: [CardService],
  exports: [CardService],
})
export class CardModule {}
