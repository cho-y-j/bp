import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/models.dart';
import 'auth.dart';

/// 알림 목록 + 미읽음 수.
final notificationsProvider = FutureProvider<NotificationList>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/notifications');
  return NotificationList.fromJson(res as Map);
});

/// 홈 벨 뱃지용 미읽음 카운트만.
final unreadCountProvider = FutureProvider<int>((ref) async {
  final list = await ref.watch(notificationsProvider.future);
  return list.unreadCount;
});

class NotificationsRepo {
  final ApiClient api;
  NotificationsRepo(this.api);

  Future<void> markRead(String id) => api.post('/notifications/$id/read');

  /// 폭염 안전 알림 "확인" (ack).
  Future<void> ackSafety(String logId) => api.post('/safety/$logId/ack');

  /// TBM 참석자 "확인" (ack).
  Future<void> ackTbm(String attendeeId) => api.post('/tbm/$attendeeId/ack');

  /// FCM 디바이스 토큰 등록.
  Future<void> registerDeviceToken(String token, String platform) =>
      api.post('/device-tokens', body: {'token': token, 'platform': platform});
}

final notificationsRepoProvider = Provider<NotificationsRepo>(
    (ref) => NotificationsRepo(ref.watch(apiClientProvider)));
