import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/models.dart';
import 'auth.dart';

/// 내 사업장 목록.
final myBusinessesProvider = FutureProvider<List<BusinessItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/businesses/mine');
  final list = (res as Map)['businesses'] as List? ?? [];
  return list.map((e) => BusinessItem.fromJson(e as Map)).toList();
});

/// 내 연결 목록(전체 — 사업장/작업자 양측).
final allConnectionsProvider =
    FutureProvider<List<ConnectionItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/connections');
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => ConnectionItem.fromJson(e as Map)).toList();
});

/// 내 사업장 지급 신뢰도 배지 상태 (P3a). 사업장 미보유면 null.
final myPaymentBadgeProvider = FutureProvider<Map?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.get('/biz/payment-badge');
    return res as Map;
  } on ApiException catch (e) {
    if (e.code == 'BUSINESS_NOT_FOUND' || e.status == 404) return null;
    rethrow;
  }
});

/// 수신함(사업장 대상 확인서).
final inboxProvider = FutureProvider<List<InboxItem>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/biz/inbox');
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => InboxItem.fromJson(e as Map)).toList();
});

/// 정산: 월별 작업자 미지급.
final settlementsProvider =
    FutureProvider.family<List<SettlementWorker>, String>((ref, month) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/biz/settlements', query: {'month': month});
  final workers = (res as Map)['workers'] as List? ?? [];
  return workers.map((e) => SettlementWorker.fromJson(e as Map)).toList();
});

/// 작업 지시 목록(월별, 양측).
final jobsProvider =
    FutureProvider.family<List<JobItem>, String>((ref, month) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/jobs', query: {'month': month});
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => JobItem.fromJson(e as Map)).toList();
});

void invalidateBiz(WidgetRef ref) {
  ref.invalidate(myBusinessesProvider);
  ref.invalidate(allConnectionsProvider);
  ref.invalidate(inboxProvider);
  ref.invalidate(settlementsProvider);
  ref.invalidate(jobsProvider);
}

class BizRepo {
  final ApiClient api;
  BizRepo(this.api);

  Future<BusinessItem> createBusiness(
      {required String name, String? businessNumber}) async {
    final res = await api.post('/businesses', body: {
      'name': name,
      if (businessNumber != null && businessNumber.isNotEmpty)
        'businessNumber': businessNumber,
    });
    return BusinessItem.fromJson(res as Map);
  }

  Future<List<BusinessItem>> searchBusiness(String q) async {
    final res = await api.get('/businesses/search', query: {'q': q});
    final items = (res as Map)['items'] as List? ?? [];
    return items.map((e) => BusinessItem.fromJson(e as Map)).toList();
  }

  /// 내 사업장의 지급 신뢰도 배지 상태 (P3a). businessId 생략 시 첫 사업장.
  /// 사업장 미보유(404 BUSINESS_NOT_FOUND) 면 null 반환.
  Future<Map?> businessBadge({String? businessId}) async {
    try {
      final res = await api.get('/biz/payment-badge',
          query: {'businessId': ?businessId});
      return res as Map;
    } on ApiException catch (e) {
      if (e.code == 'BUSINESS_NOT_FOUND' || e.status == 404) return null;
      rethrow;
    }
  }

  /// 특정 사업장의 지급 신뢰도 배지 (P3a) — GET /businesses/:id 의 paymentBadge.
  Future<PaymentBadge?> businessBadgeById(String id) async {
    final res = await api.get('/businesses/$id');
    return PaymentBadge.parse((res as Map)['paymentBadge']);
  }

  Future<List<WorkerSearchItem>> searchWorkers(String phone) async {
    final res = await api.get('/workers/search', query: {'phone': phone});
    final items = (res as Map)['items'] as List? ?? [];
    return items.map((e) => WorkerSearchItem.fromJson(e as Map)).toList();
  }

  /// 사업장 → 작업자 연결 요청.
  Future<void> requestConnection(
          {required String businessId, required String workerProfileId}) =>
      api.post('/connections', body: {
        'businessId': businessId,
        'workerProfileId': workerProfileId,
        'path': 'PHONE_SEARCH',
      });

  Future<void> acceptConnection(String id) =>
      api.post('/connections/$id/accept');

  /// 작업 지시 생성. scheduledAt 은 ISO8601(로컬).
  Future<JobItem> createJob({
    required String businessId,
    required String workerProfileId,
    required String site,
    required DateTime scheduledAt,
    required String rateType,
    required int rate,
  }) async {
    final res = await api.post('/jobs', body: {
      'businessId': businessId,
      'workerProfileId': workerProfileId,
      'site': site,
      'scheduledAt': scheduledAt.toIso8601String(),
      'rateType': rateType,
      'rate': rate,
    });
    return JobItem.fromJson(res as Map);
  }

  // 작업자 측 작업 흐름
  Future<void> confirmJob(String id) => api.post('/jobs/$id/confirm');

  Future<void> startJob(String id,
          {required double lat,
          required double lng,
          required String condition,
          String? note}) =>
      api.post('/jobs/$id/start', body: {
        'lat': lat,
        'lng': lng,
        'condition': condition,
        if (note != null && note.isNotEmpty) 'conditionNote': note,
      });

  Future<void> completeJob(String id,
          {required double lat,
          required double lng,
          List<String>? photoPaths}) =>
      api.post('/jobs/$id/complete', body: {
        'lat': lat,
        'lng': lng,
        'photoPaths': ?photoPaths,
      });

  // 수신함 상세 + 앱내 서명
  Future<BizConfirmationDetail> confirmationDetail(String id) async {
    final res = await api.get('/biz/confirmations/$id');
    return BizConfirmationDetail.fromJson(res as Map);
  }

  Future<void> signConfirmation(String id,
          {required String signerName, required String signImageBase64}) =>
      api.post('/biz/confirmations/$id/sign',
          body: {'signerName': signerName, 'signImageBase64': signImageBase64});

  // 정산 지급
  Future<Map> pay(List<String> ledgerEntryIds) async {
    final res = await api
        .post('/biz/settlements/pay', body: {'ledgerEntryIds': ledgerEntryIds});
    return res as Map;
  }

  // 안전 리포트 PDF (인증 blob)
  Future<Uint8List> safetyReport(String month) async {
    final bytes =
        await api.getBytes('/biz/safety-report', query: {'month': month});
    return Uint8List.fromList(bytes);
  }
}

final bizRepoProvider =
    Provider<BizRepo>((ref) => BizRepo(ref.watch(apiClientProvider)));
