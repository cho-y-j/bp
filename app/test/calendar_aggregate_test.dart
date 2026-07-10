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
}
