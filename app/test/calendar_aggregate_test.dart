import 'package:flutter_test/flutter_test.dart';
import 'package:workon/models/models.dart';

void main() {
  group('캘린더 월 집계 매핑 (confirmations?month= byDate)', () {
    final json = {
      'month': '2026-07',
      'count': 3,
      'totalAmount': 1640000,
      'byDate': [
        {'date': '2026-07-03', 'count': 1, 'totalAmount': 550000},
        {'date': '2026-07-07', 'count': 2, 'totalAmount': 1090000},
      ],
      'items': [
        {'id': 'a', 'date': '2026-07-03', 'siteName': 'S1', 'companyName': 'C', 'total': 550000},
        {'id': 'b', 'date': '2026-07-07', 'siteName': 'S2', 'companyName': 'C', 'total': 545000},
        {'id': 'c', 'date': '2026-07-07', 'siteName': 'S3', 'companyName': 'C', 'total': 545000},
      ],
    };

    test('byDateMap 이 일자 → 집계로 매핑된다', () {
      final list = ConfirmationList.fromJson(json);
      final map = list.byDateMap;
      expect(map.length, 2);
      expect(map['2026-07-03']!.count, 1);
      expect(map['2026-07-03']!.totalAmount, 550000);
      expect(map['2026-07-07']!.count, 2);
      expect(map['2026-07-07']!.totalAmount, 1090000);
      expect(map.containsKey('2026-07-05'), isFalse);
    });

    test('총계/건수 파싱', () {
      final list = ConfirmationList.fromJson(json);
      expect(list.count, 3);
      expect(list.totalAmount, 1640000);
      expect(list.items.length, 3);
    });
  });

  group('정산 분리 매핑 (settlement / paid·outstanding)', () {
    final json = {
      'month': '2026-07',
      'count': 3,
      'totalAmount': 650000, // billed
      'totalPaid': 320000,
      'totalOutstanding': 330000,
      'byDate': [
        // 완납 날(미수 0) → fullyPaid=true
        {
          'date': '2026-07-11',
          'count': 1,
          'totalAmount': 220000,
          'paidAmount': 220000,
          'outstandingAmount': 0,
        },
        // 부분입금 날(미수 잔존) → fullyPaid=false
        {
          'date': '2026-07-14',
          'count': 1,
          'totalAmount': 180000,
          'paidAmount': 100000,
          'outstandingAmount': 80000,
        },
        // 미입금 날 → fullyPaid=false
        {
          'date': '2026-07-17',
          'count': 1,
          'totalAmount': 250000,
          'paidAmount': 0,
          'outstandingAmount': 250000,
        },
      ],
      'items': [
        {
          'id': 'p',
          'date': '2026-07-11',
          'siteName': 'S',
          'companyName': 'C',
          'total': 220000,
          'settlement': {
            'paidAmount': 220000,
            'outstandingAmount': 0,
            'status': 'PAID',
          },
        },
        {
          'id': 'q',
          'date': '2026-07-14',
          'siteName': 'S',
          'companyName': 'C',
          'total': 180000,
          'settlement': {
            'paidAmount': 100000,
            'outstandingAmount': 80000,
            'status': 'PARTIAL',
          },
        },
        {
          'id': 'r',
          'date': '2026-07-17',
          'siteName': 'S',
          'companyName': 'C',
          'total': 250000,
          'settlement': {
            'paidAmount': 0,
            'outstandingAmount': 250000,
            'status': 'UNPAID',
          },
        },
      ],
    };

    test('월 총계에 미수/입금 분리 필드가 파싱된다 (받을 돈 = totalOutstanding)', () {
      final list = ConfirmationList.fromJson(json);
      expect(list.totalAmount, 650000);
      expect(list.totalPaid, 320000);
      expect(list.totalOutstanding, 330000);
    });

    test('DayAggregate.fullyPaid: 미수 0 인 날만 true', () {
      final map = ConfirmationList.fromJson(json).byDateMap;
      expect(map['2026-07-11']!.fullyPaid, isTrue);
      expect(map['2026-07-14']!.fullyPaid, isFalse);
      expect(map['2026-07-17']!.fullyPaid, isFalse);
    });

    test('Confirmation.settlement 및 isFullyPaid 파싱', () {
      final items = ConfirmationList.fromJson(json).items;
      final paid = items.firstWhere((x) => x.id == 'p');
      final partial = items.firstWhere((x) => x.id == 'q');
      final unpaid = items.firstWhere((x) => x.id == 'r');
      expect(paid.isFullyPaid, isTrue);
      expect(paid.settlement!.status, 'PAID');
      expect(partial.isFullyPaid, isFalse);
      expect(partial.settlement!.isPartial, isTrue);
      expect(partial.settlement!.paidAmount, 100000);
      expect(unpaid.isFullyPaid, isFalse);
      expect(unpaid.settlement!.status, 'UNPAID');
    });

    test('teamShares(팀원 파생 소득) 파싱 + 총계/건수 포함', () {
      final list = ConfirmationList.fromJson({
        'month': '2026-07',
        // 서버가 확인서(items) + teamShares 를 합산해 내려주는 형태.
        'count': 2, // 확인서 1 + 팀 작업 1
        'totalAmount': 400000,
        'totalPaid': 100000,
        'totalOutstanding': 300000,
        'byDate': [
          {
            'date': '2026-07-09',
            'count': 1,
            'totalAmount': 220000,
            'paidAmount': 0,
            'outstandingAmount': 220000,
          },
          {
            'date': '2026-07-10',
            'count': 1,
            'totalAmount': 180000,
            'paidAmount': 100000,
            'outstandingAmount': 80000,
          },
        ],
        'items': [
          {
            'id': 'own',
            'date': '2026-07-09',
            'siteName': '판교',
            'companyName': 'C',
            'total': 220000,
            'settlement': {
              'paidAmount': 0,
              'outstandingAmount': 220000,
              'status': 'UNPAID',
            },
          },
        ],
        'teamShares': [
          {
            'id': 'ts1',
            'date': '2026-07-10',
            'site': '역삼 리모델링',
            'teamLeaderName': '박현장',
            'amount': 180000,
            'settlement': {
              'paidAmount': 100000,
              'outstandingAmount': 80000,
              'status': 'PARTIAL',
            },
          },
        ],
      });
      expect(list.teamShares.length, 1);
      final ts = list.teamShares.first;
      expect(ts.id, 'ts1');
      expect(ts.site, '역삼 리모델링');
      expect(ts.teamLeaderName, '박현장');
      expect(ts.amount, 180000);
      expect(ts.isFullyPaid, isFalse);
      expect(ts.settlement!.isPartial, isTrue);
      expect(ts.settlement!.paidAmount, 100000);
      // 서버가 이미 teamShares 를 포함해 집계 → 앱은 총계/건수를 그대로 신뢰.
      expect(list.count, 2);
      expect(list.totalAmount, 400000);
      expect(list.totalPaid, 100000);
      expect(list.totalOutstanding, 300000);
    });

    test('teamShares 완납 시 isFullyPaid=true, 누락 시 빈 리스트', () {
      final paid = TeamShare.fromJson({
        'id': 't',
        'date': '2026-07-01',
        'site': 'S',
        'teamLeaderName': '김반장',
        'amount': 150000,
        'settlement': {
          'paidAmount': 150000,
          'outstandingAmount': 0,
          'status': 'PAID',
        },
      });
      expect(paid.isFullyPaid, isTrue);
      // teamShares 키가 없으면 빈 리스트로 안전 파싱.
      final list = ConfirmationList.fromJson({
        'count': 0,
        'totalAmount': 0,
        'byDate': [],
        'items': [],
      });
      expect(list.teamShares, isEmpty);
    });

    test('settlement 누락 시 isFullyPaid=false, byDate 필드 0 기본', () {
      final list = ConfirmationList.fromJson({
        'count': 1,
        'totalAmount': 100000,
        'byDate': [
          {'date': '2026-07-01', 'count': 1, 'totalAmount': 100000},
        ],
        'items': [
          {'id': 'x', 'date': '2026-07-01', 'siteName': 'S', 'companyName': 'C', 'total': 100000},
        ],
      });
      expect(list.totalPaid, 0);
      expect(list.totalOutstanding, 0);
      expect(list.items.first.settlement, isNull);
      expect(list.items.first.isFullyPaid, isFalse);
      expect(list.byDateMap['2026-07-01']!.outstandingAmount, 0);
      // 미수 0·count>0 → fullyPaid true(서버가 항상 정산 필드를 내려주는 정상 경로 아님을 감안한 방어값)
      expect(list.byDateMap['2026-07-01']!.fullyPaid, isTrue);
    });
  });
}
