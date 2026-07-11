import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/l10n/app_localizations.dart';
import 'package:workon/models/models.dart';
import 'package:workon/providers/data.dart';
import 'package:workon/theme/app_theme.dart';
import 'package:workon/widgets/paper_labor_contract.dart';
import 'package:workon/features/biz/contracts_screen.dart';
import 'package:workon/features/wallet/my_contracts_screen.dart';

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ko'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );

Map<String, dynamic> _dto({
  String status = 'DRAFT',
  bool employerSigned = false,
  bool workerSigned = false,
  String? endDate,
}) =>
    {
      'id': 'ct1',
      'status': status,
      'statusLabel': '작성됨',
      'businessId': 'b1',
      'businessName': '삼성물산',
      'title': '표준근로계약서',
      'workerProfileId': null,
      'workerLinked': false,
      'workerName': '김근로',
      'workerPhone': '01088882222',
      'startDate': '2026-07-15',
      'endDate': endDate,
      'workplace': '강남 A현장',
      'jobDescription': '철근공',
      'workStartTime': '08:00',
      'workEndTime': '17:00',
      'breakTime': '12:00~13:00',
      'wageType': 'DAILY',
      'wageTypeLabel': '일급',
      'wageAmount': 180000,
      'payday': '매월 25일',
      'payMethod': '계좌이체',
      'weeklyHolidayAllowance': false,
      'overtimeAllowance': true,
      'socialInsurance': {
        'employment': true,
        'health': false,
        'pension': false,
        'industrialAccident': true,
      },
      'specialTerms': '우천시 협의',
      'employerSigned': employerSigned,
      'employerSignerName': employerSigned ? '홍사장' : null,
      'employerSignedAt': employerSigned ? '2026-07-11 10:00' : null,
      'workerSigned': workerSigned,
      'workerSignerName': workerSigned ? '김근로' : null,
      'workerSignedAt': workerSigned ? '2026-07-11 11:00' : null,
      'shareToken': 'tok123',
      'revokedAt': null,
      'viewCount': 0,
      'createdAt': '2026-07-11T07:00:00.000Z',
      'updatedAt': '2026-07-11T07:00:00.000Z',
    };

void main() {
  group('LaborContract 모델 파싱', () {
    test('필드 매핑 + socialInsurance Map 파싱', () {
      final c = LaborContract.fromJson(_dto());
      expect(c.id, 'ct1');
      expect(c.status, 'DRAFT');
      expect(c.isDraft, isTrue);
      expect(c.businessName, '삼성물산');
      expect(c.workerName, '김근로');
      expect(c.startDate, '2026-07-15');
      expect(c.endDate, isNull);
      expect(c.wageType, 'DAILY');
      expect(c.wageAmount, 180000);
      expect(c.payday, '매월 25일');
      expect(c.weeklyHolidayAllowance, isFalse);
      expect(c.overtimeAllowance, isTrue);
      expect(c.insEmployment(), isTrue);
      expect(c.insHealth(), isFalse);
      expect(c.insPension(), isFalse);
      expect(c.insAccident(), isTrue);
      expect(c.employerSigned, isFalse);
      expect(c.specialTerms, '우천시 협의');
    });

    test('상태 판별 + 서명 필드', () {
      final signed = LaborContract.fromJson(
          _dto(status: 'SIGNED', employerSigned: true, workerSigned: true));
      expect(signed.isSigned, isTrue);
      expect(signed.employerSigned, isTrue);
      expect(signed.employerSignerName, '홍사장');
      expect(signed.workerSigned, isTrue);
      expect(signed.workerSignerName, '김근로');

      final sent = LaborContract.fromJson(_dto(status: 'SENT', employerSigned: true));
      expect(sent.isSent, isTrue);
      expect(sent.workerSigned, isFalse);
    });

    test('socialInsurance 누락 시 false 처리', () {
      final c = LaborContract.fromJson({'id': 'x', 'status': 'DRAFT'});
      expect(c.insEmployment(), isFalse);
      expect(c.insAccident(), isFalse);
      expect(c.socialInsurance, isNull);
    });
  });

  group('PaperLaborContract 렌더', () {
    testWidgets('조항 라벨(번역)과 계약 데이터를 표시한다', (tester) async {
      final c = LaborContract.fromJson(_dto());
      await tester.pumpWidget(_app(
          Scaffold(body: SingleChildScrollView(child: PaperLaborContract(c: c))),
          const []));
      await tester.pumpAndSettle();
      // 조항 라벨(ko)
      expect(find.text('계약 당사자'), findsOneWidget);
      expect(find.text('사업주(갑)'), findsOneWidget);
      expect(find.text('근로자(을)'), findsOneWidget);
      expect(find.text('근무장소'), findsOneWidget);
      expect(find.text('사회보험 적용'), findsOneWidget);
      // 계약 데이터 값
      expect(find.text('삼성물산'), findsOneWidget);
      expect(find.text('김근로'), findsOneWidget);
      expect(find.text('강남 A현장'), findsOneWidget);
      // 4대보험 적용/미적용
      expect(find.text('적용'), findsWidgets);
      expect(find.text('미적용'), findsWidgets);
      // 정본(한국어본) 안내 문구
      expect(find.textContaining('정본은 한국어본'), findsOneWidget);
    });
  });

  group('계약서 목록 화면', () {
    testWidgets('사업장 계약서 비어있으면 빈 상태', (tester) async {
      await tester.pumpWidget(_app(const ContractsScreen(), [
        bizContractsProvider.overrideWith((ref) async => <LaborContract>[]),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('아직 계약서가 없어요'), findsOneWidget);
    });

    testWidgets('사업장 계약서 목록 + 상태 배지', (tester) async {
      await tester.pumpWidget(_app(const ContractsScreen(), [
        bizContractsProvider.overrideWith(
            (ref) async => [LaborContract.fromJson(_dto())]),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('김근로'), findsOneWidget);
      expect(find.text('강남 A현장'), findsOneWidget);
      expect(find.text('작성됨'), findsOneWidget); // 상태 배지
    });

    testWidgets('내 계약서(작업자) 목록 + 서명됨 배지', (tester) async {
      await tester.pumpWidget(_app(const MyContractsScreen(), [
        myContractsProvider.overrideWith((ref) async =>
            [LaborContract.fromJson(_dto(status: 'SIGNED', employerSigned: true, workerSigned: true))]),
      ]));
      await tester.pumpAndSettle();
      expect(find.text('삼성물산'), findsOneWidget);
      expect(find.text('서명됨'), findsOneWidget);
    });
  });
}
