import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/l10n/app_localizations.dart';
import 'package:workon/models/models.dart';
import 'package:workon/theme/app_theme.dart';
import 'package:workon/providers/biz.dart';
import 'package:workon/features/biz/attendance_board_screen.dart';
import 'package:workon/features/biz/wage_statement_screen.dart';

Widget _app(Widget home, {List<Override> overrides = const []}) => ProviderScope(
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

// 백엔드 계약(P5a)과 동일한 형태의 지급명세서 DTO.
// 김*수 60만/3일 → 3.3%: 소득세 18,000·지방 1,800·합계 19,800·차인 580,200
//                  → 일용: 소득세 4,050·지방 400·합계 4,450·차인 595,550
Map<String, dynamic> _wageDto() => {
      'month': '2026-07',
      'businessName': '현대ENG',
      'marked': false,
      'workers': [
        {
          'workerName': '김*수',
          'paidTotal': 600000,
          'paymentCount': 1,
          'workDays': 3,
          'business3_3': {
            'incomeTax': 18000,
            'localTax': 1800,
            'totalTax': 19800,
            'netPay': 580200,
          },
          'dailyWage': {
            'incomeTax': 4050,
            'localTax': 400,
            'totalTax': 4450,
            'netPay': 595550,
          },
        },
      ],
      'totals': {
        'workerCount': 1,
        'paidTotal': 600000,
        'paymentCount': 1,
        'business3_3': {
          'incomeTax': 18000,
          'localTax': 1800,
          'totalTax': 19800,
          'netPay': 580200,
        },
        'dailyWage': {
          'incomeTax': 4050,
          'localTax': 400,
          'totalTax': 4450,
          'netPay': 595550,
        },
      },
      'notes': [
        '세율은 2026년 기준 참고값입니다. 세법 개정 여부를 확인하세요.',
        '세무 상담이 아닙니다. 세무 전문가 확인을 권장합니다.',
        '주민등록번호는 수집·저장하지 않습니다.',
      ],
      'hometaxNote': '홈택스 지급명세서 제출 시 주민등록번호를 직접 입력하세요.',
      'copyText': '2026-07 현대ENG 지급명세서\n김*수 600,000원 ...',
    };

Map<String, dynamic> _attendanceDto() => {
      'date': '2026-07-17',
      'sites': [
        {
          'site': '역삼 현장',
          'workers': [
            {
              'jobId': 'j1',
              'workerName': '김*수',
              'status': 'DONE',
              'scheduledAt': '08:00',
              'startedAt': '08:05',
              'finishedAt': '17:00',
              'condition': 'OK',
            },
            {
              'jobId': 'j2',
              'workerName': '이*호',
              'status': 'STARTED',
              'scheduledAt': '08:00',
              'startedAt': '08:10',
              'condition': 'BAD',
            },
            {
              'jobId': 'j3',
              'workerName': '박*민',
              'status': 'SCHEDULED',
              'scheduledAt': '09:00',
            },
          ],
          'summary': {
            'total': 3,
            'attended': 2,
            'completed': 1,
            'absent': 1,
          },
        },
      ],
      'summary': {'total': 3, 'attended': 2, 'completed': 1, 'absent': 1},
    };

void main() {
  test('WageStatement.fromJson — 소득 유형별 세액 매핑', () {
    final w = WageStatement.fromJson(_wageDto());
    expect(w.workers.length, 1);
    final worker = w.workers.first;
    expect(worker.workerName, '김*수');
    expect(worker.paidTotal, 600000);
    // 3.3% 사업소득
    expect(worker.business33.incomeTax, 18000);
    expect(worker.business33.localTax, 1800);
    expect(worker.business33.totalTax, 19800);
    expect(worker.business33.netPay, 580200);
    // 일용근로
    expect(worker.dailyWage.incomeTax, 4050);
    expect(worker.dailyWage.totalTax, 4450);
    expect(worker.dailyWage.netPay, 595550);
    // 총계도 동일하게 매핑
    expect(w.totals.business33.totalTax, 19800);
    expect(w.totals.dailyWage.totalTax, 4450);
    expect(w.notes.length, 3);
    expect(w.hometaxNote.contains('홈택스'), true);
  });

  test('AttendanceSummary — 요약 카운트 매핑(전체/출근/완료/미출근)', () {
    final a = TodayAttendance.fromJson(_attendanceDto());
    expect(a.sites.length, 1);
    final s = a.summary;
    expect(attendanceSummaryCounts(s), [3, 2, 1, 1]);
    final site = a.sites.first.summary;
    expect(attendanceSummaryCounts(site), [3, 2, 1, 1]);
    // 상태·컨디션 파싱
    expect(a.sites.first.workers[0].status, 'DONE');
    expect(a.sites.first.workers[0].condition, 'OK');
    expect(a.sites.first.workers[1].condition, 'BAD');
  });

  test('SiteCosts.fromJson — 현장·연인원·팀 인원 매핑', () {
    final dto = {
      'range': {'from': '2026-06', 'to': '2026-07'},
      'businessName': '현대ENG',
      'sites': [
        {
          'site': '역삼 현장',
          'entries': [
            {
              'workerName': '김*수',
              'isTeam': true,
              'teamMemberCount': 3,
              'days': 4.5,
              'gongsu': 4.5,
              'amount': 810000,
              'entryCount': 1,
            },
          ],
          'subtotalAmount': 810000,
          'subtotalDays': 4.5,
          'subtotalGongsu': 4.5,
          'workerCount': 1,
        },
      ],
      'totals': {
        'totalAmount': 810000,
        'totalDays': 4.5,
        'totalGongsu': 4.5,
        'siteCount': 1,
        'entryCount': 1,
      },
    };
    final s = SiteCosts.fromJson(dto);
    expect(s.rangeFrom, '2026-06');
    expect(s.rangeTo, '2026-07');
    expect(s.sites.first.entries.first.isTeam, true);
    expect(s.sites.first.entries.first.teamMemberCount, 3);
    expect(s.sites.first.entries.first.days, 4.5);
    expect(s.totals.totalAmount, 810000);
  });

  testWidgets('세액 표시 포맷 — wageWithholdingSummary tabular 천단위', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    const tax = WageTax(18000, 1800, 19800, 580200);
    final line = wageWithholdingSummary(l, tax, 'ko');
    expect(line.contains('19,800원'), true); // 원천징수 합계
    expect(line.contains('580,200원'), true); // 차인지급액
  });

  testWidgets('지급명세서 화면 — 세액·차인지급액 렌더 + 소득유형 토글', (tester) async {
    await tester.pumpWidget(_app(
      const WageStatementScreen(),
      overrides: [
        wageStatementProvider.overrideWith(
            (ref, month) async => WageStatement.fromJson(_wageDto())),
      ],
    ));
    await tester.pumpAndSettle();

    // 기본(사업소득 3.3%) 세액 표시
    expect(find.text('600,000원'), findsWidgets); // 지급액
    expect(find.text('18,000원'), findsWidgets); // 소득세(3.3%)
    expect(find.text('580,200원'), findsWidgets); // 차인지급액(3.3%)
    // 안내 노트(세무사 확인 권장·홈택스 직접 입력) 필수 표시
    expect(find.textContaining('세무 전문가 확인'), findsOneWidget);
    expect(find.textContaining('홈택스'), findsOneWidget);

    // 일용근로 토글 → 세액 변경
    await tester.tap(find.text('일용근로'));
    await tester.pumpAndSettle();
    expect(find.text('4,050원'), findsWidgets); // 소득세(일용)
    expect(find.text('595,550원'), findsWidgets); // 차인지급액(일용)
  });

  testWidgets('출역 현황판 상세 — 요약 카운트 렌더', (tester) async {
    await tester.pumpWidget(_app(
      const AttendanceBoardScreen(),
      overrides: [
        todayAttendanceProvider
            .overrideWith((ref) async => TodayAttendance.fromJson(_attendanceDto())),
      ],
    ));
    await tester.pumpAndSettle();
    // 현장명·상태 렌더
    expect(find.text('역삼 현장'), findsOneWidget);
    expect(find.text('완료'), findsWidgets); // DONE 상태 배지 + 요약 라벨
    expect(find.text('김*수'), findsOneWidget);
    expect(find.text('이*호'), findsOneWidget);
  });
}
