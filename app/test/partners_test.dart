import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/partner_prompt_store.dart';
import 'package:workon/models/models.dart';

void main() {
  group('PartnerPromptStore.normPhone', () {
    test('하이픈·공백·기호 제거 후 숫자만 남긴다', () {
      expect(PartnerPromptStore.normPhone('010-1234-5678'), '01012345678');
      expect(PartnerPromptStore.normPhone(' 010 1234 5678 '), '01012345678');
      expect(PartnerPromptStore.normPhone('+82 10-1234-5678'), '821012345678');
    });
    test('같은 번호 다른 표기는 같은 키로 정규화(중복 판정 근거)', () {
      expect(PartnerPromptStore.normPhone('010-1234-5678'),
          PartnerPromptStore.normPhone('01012345678'));
    });
    test('숫자가 없으면 빈 문자열', () {
      expect(PartnerPromptStore.normPhone('이름만'), '');
    });
  });

  group('Partner.fromJson', () {
    test('수기 거래처(id 있음) — isManual true, 숫자 파싱', () {
      final p = Partner.fromJson({
        'id': 'p1',
        'businessId': null,
        'linked': false,
        'name': '삼정건설',
        'phone': '010-1234-5678',
        'alias': '삼정',
        'bizNumber': '123-45-67890',
        'email': 'a@b.com',
        'memo': '메모',
        'confirmationCount': 3,
        'outstanding': 250000,
        'paid': 0,
        'lastWorkedDate': '2026-07-15',
      });
      expect(p.id, 'p1');
      expect(p.isManual, true);
      expect(p.linked, false);
      expect(p.name, '삼정건설');
      expect(p.phone, '010-1234-5678');
      expect(p.alias, '삼정');
      expect(p.confirmationCount, 3);
      expect(p.outstanding, 250000);
      expect(p.paid, 0);
      expect(p.lastWorkedDate, '2026-07-15');
    });

    test('연결(승격) 거래처(id null) — isManual false, linked true', () {
      final p = Partner.fromJson({
        'id': null,
        'businessId': 'biz1',
        'linked': true,
        'name': '코리아건설',
        'phone': null,
        'confirmationCount': 5,
        'outstanding': 300000,
        'paid': 100000,
        'lastWorkedDate': null,
      });
      expect(p.id, isNull);
      expect(p.isManual, false);
      expect(p.linked, true);
      expect(p.businessId, 'biz1');
      expect(p.phone, isNull);
      expect(p.outstanding, 300000);
      expect(p.paid, 100000);
      expect(p.lastWorkedDate, isNull);
      // 보강 필드 누락 시 null.
      expect(p.alias, isNull);
      expect(p.bizNumber, isNull);
      expect(p.email, isNull);
      expect(p.memo, isNull);
    });

    test('숫자 필드가 문자열/누락이어도 안전 파싱', () {
      final p = Partner.fromJson({
        'id': 'p2',
        'linked': false,
        'name': '대영ENG',
        'outstanding': '150000', // 문자열
        // confirmationCount / paid 누락 → 0
      });
      expect(p.outstanding, 150000);
      expect(p.confirmationCount, 0);
      expect(p.paid, 0);
    });
  });
}
