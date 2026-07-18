import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/models.dart';
import 'auth.dart';

/// 거래처 목록 (GET /partners — 최근 작업일 desc 정렬은 서버가 처리).
final partnersProvider = FutureProvider<List<Partner>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/partners');
  final items = (res as Map)['items'] as List? ?? [];
  return items.map((e) => Partner.fromJson(e as Map)).toList();
});

/// 거래처 쓰기 액션(수기 거래처만 대상). WalletRepo 패턴.
class PartnersRepo {
  final ApiClient api;
  PartnersRepo(this.api);

  /// 보강 정보 수정 → 갱신된 거래처. 빈 문자열은 서버가 null(비우기) 처리.
  Future<Partner> patch(
    String id, {
    String? alias,
    String? bizNumber,
    String? email,
    String? memo,
  }) async {
    final res = await api.patch('/partners/$id', body: {
      'alias': ?alias,
      'bizNumber': ?bizNumber,
      'email': ?email,
      'memo': ?memo,
    });
    return Partner.fromJson(res as Map);
  }

  /// 삭제(hard delete). 확인서가 남아 있으면 다음 GET 에서 자동 재수집됨.
  Future<void> remove(String id) => api.delete('/partners/$id');
}

final partnersRepoProvider =
    Provider<PartnersRepo>((ref) => PartnersRepo(ref.watch(apiClientProvider)));
