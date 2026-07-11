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

/// 내 팀(반장 명단) 목록.
final teamsProvider = FutureProvider<List<Team>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/teams');
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => Team.fromJson(e as Map)).toList();
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

/// 사업장(대표) 표준근로계약서 목록 — GET /biz/contracts.
final bizContractsProvider = FutureProvider<List<LaborContract>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/biz/contracts');
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => LaborContract.fromJson(e as Map)).toList();
});

/// 작업자(내가 근로자)에게 온 계약서 목록 — GET /contracts (내 계약서).
final myContractsProvider = FutureProvider<List<LaborContract>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/contracts');
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => LaborContract.fromJson(e as Map)).toList();
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

  // ── 팀(반장) ─────────────────────────────────────────────
  Future<Team> createTeam(String name) async {
    final res = await api.post('/teams', body: {'name': name});
    return Team.fromJson(res as Map);
  }

  Future<Team> updateTeam(String id, String name) async {
    final res = await api.patch('/teams/$id', body: {'name': name});
    return Team.fromJson(res as Map);
  }

  Future<void> deleteTeam(String id) => api.delete('/teams/$id');

  /// 가입 연결로 팀원 추가(서버가 프로필에서 이름 스냅샷).
  Future<TeamMember> addTeamMemberByProfile(String teamId, String profileId,
      {int? defaultRate}) async {
    final res = await api.post('/teams/$teamId/members', body: {
      'profileId': profileId,
      'defaultRate': ?defaultRate,
    });
    return TeamMember.fromJson(res as Map);
  }

  /// 수기로 팀원 추가.
  Future<TeamMember> addTeamMemberManual(String teamId,
      {required String name, String? phone, int? defaultRate}) async {
    final res = await api.post('/teams/$teamId/members', body: {
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'defaultRate': ?defaultRate,
    });
    return TeamMember.fromJson(res as Map);
  }

  Future<TeamMember> updateTeamMember(String teamId, String memberId,
      {String? name, String? phone, int? defaultRate}) async {
    final res = await api.patch('/teams/$teamId/members/$memberId', body: {
      'name': ?name,
      'phone': ?phone,
      'defaultRate': ?defaultRate,
    });
    return TeamMember.fromJson(res as Map);
  }

  Future<void> deleteTeamMember(String teamId, String memberId) =>
      api.delete('/teams/$teamId/members/$memberId');

  /// 전화번호로 가입 작업자 검색(동의자만).
  Future<List<WorkerSearchItem>> searchWorkers(String phone) async {
    final res = await api.get('/workers/search', query: {'phone': phone});
    final items = (res as Map)['items'] as List? ?? [];
    return items.map((e) => WorkerSearchItem.fromJson(e as Map)).toList();
  }

  // ── 표준근로계약서 (전자서명) ─────────────────────────────
  /// 계약서 생성(사업장 모드). body 는 POST /biz/contracts 본문 그대로.
  Future<LaborContract> createLaborContract(Map<String, dynamic> body) async {
    final res = await api.post('/biz/contracts', body: body);
    return LaborContract.fromJson(res as Map);
  }

  /// 계약서 상세(사업장 측).
  Future<LaborContract> bizContract(String id) async {
    final res = await api.get('/biz/contracts/$id');
    return LaborContract.fromJson(res as Map);
  }

  /// 계약서 수정(DRAFT + 미서명일 때만). 부분 필드.
  Future<LaborContract> updateLaborContract(
      String id, Map<String, dynamic> body) async {
    final res = await api.patch('/biz/contracts/$id', body: body);
    return LaborContract.fromJson(res as Map);
  }

  /// 계약서 삭제(DRAFT 만).
  Future<void> deleteLaborContract(String id) =>
      api.delete('/biz/contracts/$id');

  /// 사업장(대표) 서명.
  Future<LaborContract> signEmployerContract(String id,
      {required String signerName, required String signImageBase64}) async {
    final res = await api.post('/biz/contracts/$id/sign-employer',
        body: {'signerName': signerName, 'signImageBase64': signImageBase64});
    return LaborContract.fromJson(res as Map);
  }

  /// 작업자에게 전송 → { shareToken, url, sent, linked, notified, alimtalkSent }.
  Future<Map> sendContract(String id) async {
    final res = await api.post('/biz/contracts/$id/send');
    return res as Map;
  }

  /// 계약서 상세(작업자 측).
  Future<LaborContract> workerContract(String id) async {
    final res = await api.get('/contracts/$id');
    return LaborContract.fromJson(res as Map);
  }

  /// 작업자 앱내 서명.
  Future<LaborContract> signWorkerContract(String id,
      {required String signerName, required String signImageBase64}) async {
    final res = await api.post('/contracts/$id/sign',
        body: {'signerName': signerName, 'signImageBase64': signImageBase64});
    return LaborContract.fromJson(res as Map);
  }
}

final repoProvider = Provider<Repo>((ref) => Repo(ref.watch(apiClientProvider)));
