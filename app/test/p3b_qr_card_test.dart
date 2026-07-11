import 'package:flutter_test/flutter_test.dart';
import 'package:workon/models/models.dart';

/// P3b — 내 QR 명함 모델 파싱 검증 (GET /me/card 응답 형태).
void main() {
  Map<String, dynamic> cardDto({
    bool valid = true,
    List<Map<String, dynamic>> expired = const [],
  }) =>
      {
        'token': 'rTREMm40FyvAnMYpFKvjvQ6yE4jqyzqp',
        'url': 'http://localhost:3004/p/rTREMm40FyvAnMYpFKvjvQ6yE4jqyzqp',
        'enabled': true,
        'intro': '성실하게 일합니다',
        'viewCount': 3,
        'preview': {
          'name': '김작업',
          'industryTags': ['철근', '콘크리트'],
          'intro': '성실하게 일합니다',
          'docValidity': {
            'valid': valid,
            'count': 1,
            'withExpiryCount': 1,
            'types': ['건설기계조종사면허'],
          },
        },
        'docStatus': {
          'valid': valid,
          'withExpiryCount': 1,
          'totalCount': 1,
          'types': ['건설기계조종사면허'],
          'expiredDocs': expired,
        },
      };

  test('CardData.fromJson — 토큰/URL/공개/소개/조회수/미리보기/서류상태 파싱', () {
    final c = CardData.fromJson(cardDto());
    expect(c.token, 'rTREMm40FyvAnMYpFKvjvQ6yE4jqyzqp');
    expect(c.url, contains('/p/'));
    expect(c.enabled, isTrue);
    expect(c.intro, '성실하게 일합니다');
    expect(c.viewCount, 3);
    expect(c.name, '김작업');
    expect(c.industryTags, ['철근', '콘크리트']);
    expect(c.docStatus.valid, isTrue);
    expect(c.docStatus.totalCount, 1);
    expect(c.docStatus.expiredDocs, isEmpty);
  });

  test('CardData.fromJson — 만료 서류(expiredDocs)는 소유자용으로 파싱', () {
    final c = CardData.fromJson(cardDto(valid: false, expired: [
      {'type': '건설업기초안전보건교육', 'expiryDate': '2025-01-01', 'dday': -560},
    ]));
    expect(c.docStatus.valid, isFalse);
    expect(c.docStatus.expiredDocs, hasLength(1));
    final d = c.docStatus.expiredDocs.first;
    expect(d.type, '건설업기초안전보건교육');
    expect(d.expiryDate, DateTime(2025, 1, 1));
    expect(d.dday, -560);
  });

  test('Profile.fromJson — cardEnabled/cardIntro 파싱', () {
    final p = Profile.fromJson({
      'id': 'x',
      'name': '김작업',
      'phone': '01011112222',
      'phoneSearchConsent': false,
      'industryTags': [],
      'hasBusiness': false,
      'cardEnabled': true,
      'cardIntro': '성실하게 일합니다',
    });
    expect(p.cardEnabled, isTrue);
    expect(p.cardIntro, '성실하게 일합니다');
  });

  test('Profile.fromJson — card 필드 누락 시 안전 기본값', () {
    final p = Profile.fromJson({
      'id': 'x',
      'phone': '01000000000',
      'industryTags': [],
    });
    expect(p.cardEnabled, isFalse);
    expect(p.cardIntro, isNull);
  });
}
