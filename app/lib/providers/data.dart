import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/models.dart';
import 'auth.dart';

/// 선택된 월 (yyyy, mm 을 DateTime 의 1일로 표현). 홈/캘린더/장부 공유.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// 확인서 목록 + 일자 집계 (월 파라미터 family).
final confirmationsProvider =
    FutureProvider.family<ConfirmationList, String>((ref, month) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/confirmations', query: {'month': month});
  return ConfirmationList.fromJson(res as Map);
});

/// 장부 월 합계.
final ledgerSummaryProvider =
    FutureProvider.family<LedgerSummary, String>((ref, month) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/ledger/summary', query: {'month': month});
  return LedgerSummary.fromJson(res as Map);
});

/// 장부 회사별 집계.
final ledgerByCompanyProvider =
    FutureProvider.family<List<LedgerCompany>, String>((ref, month) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/ledger/by-company', query: {'month': month});
  final companies = (res as Map)['companies'] as List? ?? [];
  return companies.map((e) => LedgerCompany.fromJson(e as Map)).toList();
});

/// 장부 개별 항목(입금 기록용).
final ledgerEntriesProvider =
    FutureProvider.family<List<LedgerEntry>, String>((ref, month) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/ledger/entries', query: {'month': month});
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => LedgerEntry.fromJson(e as Map)).toList();
});

/// 세금계산서 1단계 데이터 (월 파라미터 family).
final taxInvoiceDataProvider =
    FutureProvider.family<TaxInvoiceData, String>((ref, month) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/ledger/tax-invoice-data', query: {'month': month});
  return TaxInvoiceData.fromJson(res as Map);
});

/// 만료 임박 서류 (홈 배너용).
final expiringDocsProvider =
    FutureProvider<List<ExpiringDoc>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/documents/expiring', query: {'days': 30});
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => ExpiringDoc.fromJson(e as Map)).toList();
});

/// 내 연결(사업장). 확인서 작성 시 상대 선택.
final connectionsProvider =
    FutureProvider<List<ConnectionItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/connections');
  final items = (res as Map)['items'] as List? ?? [];
  return items
      .map((e) => ConnectionItem.fromJson(e as Map))
      .where((c) => c.status == 'ACCEPTED')
      .toList();
});

/// 데이터 무효화 유틸 — 쓰기 후 홈/캘린더/장부 새로고침.
void invalidateAll(WidgetRef ref) {
  ref.invalidate(confirmationsProvider);
  ref.invalidate(ledgerSummaryProvider);
  ref.invalidate(ledgerByCompanyProvider);
  ref.invalidate(ledgerEntriesProvider);
  ref.invalidate(expiringDocsProvider);
  ref.invalidate(taxInvoiceDataProvider);
}

/// 쓰기 액션 모음 (확인서/입금).
class Repo {
  final ApiClient api;
  Repo(this.api);

  Future<Confirmation> createConfirmation(Map<String, dynamic> body) async {
    final res = await api.post('/confirmations', body: body);
    return Confirmation.fromJson(res as Map);
  }

  Future<Confirmation> duplicate(String id) async {
    final res = await api.post('/confirmations/$id/duplicate');
    return Confirmation.fromJson(res as Map);
  }

  /// send → { shareToken, url, linked, notified }
  Future<Map> send(String id) async {
    final res = await api.post('/confirmations/$id/send');
    return res as Map;
  }

  Future<void> addPayment(String ledgerId, int amount, {String? memo}) async {
    await api.post('/ledger/$ledgerId/payments',
        body: {'amount': amount, if (memo != null && memo.isNotEmpty) 'memo': memo});
  }

  /// 세금계산서 발행 완료 표시 → { marked, alreadyMarked, taxInvoicedAt }.
  Future<Map> markTaxInvoiced(List<String> ledgerIds) async {
    final res = await api.post('/ledger/tax-invoice-data/mark',
        body: {'ledgerIds': ledgerIds});
    return res as Map;
  }
}

final repoProvider = Provider<Repo>((ref) => Repo(ref.watch(apiClientProvider)));
