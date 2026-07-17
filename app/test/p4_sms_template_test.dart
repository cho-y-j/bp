import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/sms_template.dart';

void main() {
  group('SMS 템플릿 변수 치환', () {
    final ref = DateTime(2026, 7, 17, 14, 30); // 금요일

    test('{내이름} {상대명} {날짜} 치환', () {
      final out = renderSmsTemplate(
        '{상대명}님, {내이름}입니다. 오늘은 {날짜}',
        SmsTemplateContext(
            myName: '홍길동', counterpartName: '김반장', referenceDate: ref),
      );
      expect(out, '김반장님, 홍길동입니다. 오늘은 2026-07-17');
    });

    test('{현장} {링크} 치환', () {
      final out = renderSmsTemplate(
        '{현장} 확인서: {링크}',
        SmsTemplateContext(site: '판교현장', link: 'https://x/c/abc'),
      );
      expect(out, '판교현장 확인서: https://x/c/abc');
    });

    test('{요일} 은 한국어 요일', () {
      final out = renderSmsTemplate('{요일}',
          SmsTemplateContext(referenceDate: ref));
      expect(out, '금요일');
    });

    test('값이 없으면 빈 문자열로 치환', () {
      final out = renderSmsTemplate('[{상대명}]', SmsTemplateContext());
      expect(out, '[]');
    });

    test('미지원 변수는 원문 유지(본문 손실 방지)', () {
      final out = renderSmsTemplate('금액 {총액} 원', SmsTemplateContext());
      expect(out, '금액 {총액} 원');
    });

    test('변수 추출 — 중복 제거', () {
      final vars = extractSmsTemplateVars('{상대명} {내이름} {상대명} {링크}');
      expect(vars, ['상대명', '내이름', '링크']);
    });

    test('노출 변수 목록에 핵심 3종 포함', () {
      expect(smsTemplateVariables, containsAll(['{내이름}', '{상대명}', '{날짜}']));
    });
  });
}
