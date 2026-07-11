import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/draft_store.dart';
import 'data.dart';

/// 초안 큐 영속화 구현(테스트에서 override).
final draftStorageProvider =
    Provider<DraftStorage>((ref) => PrefsDraftStorage());

/// connectivity_plus 스트림(테스트에서 override 가능).
final connectivityStreamProvider =
    Provider<Stream<List<ConnectivityResult>>>(
        (ref) => Connectivity().onConnectivityChanged);

/// 초안 전송 결과 이벤트(자동 전송 스낵바용). MainShell 이 감지.
class DraftFlushEvent {
  final int sent; // 성공 전송 건수
  final int failed; // 서버 검증 실패로 초안에 남은 건수
  final DateTime at;
  DraftFlushEvent(this.sent, this.failed) : at = DateTime.now();
}

final draftFlushEventProvider = StateProvider<DraftFlushEvent?>((ref) => null);

/// 네트워크 실패(재시도 대상) 여부 판별 — 순수 함수(단위 테스트 대상).
/// NETWORK/타임아웃/5xx 는 아직 연결 문제 → 큐 유지. 4xx(검증)은 초안으로 유도.
bool isRetriableFailure(ApiException e) {
  if (e.code == 'NETWORK' || e.code == 'UNAUTHORIZED') return true;
  final s = e.status;
  if (s == null) return true;
  return s >= 500;
}

/// 확인서 초안 큐 컨트롤러. 저장 실패 시 enqueue, 연결 복구 시 flush.
class DraftQueue extends StateNotifier<List<ConfirmationDraft>> {
  final Ref _ref;
  final DraftStorage _storage;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _flushing = false;

  DraftQueue(this._ref, this._storage) : super(const []) {
    _init();
  }

  Future<void> _init() async {
    state = await _storage.load();
    _sub = _ref.read(connectivityStreamProvider).listen((results) {
      final online =
          results.any((r) => r != ConnectivityResult.none);
      if (online) flush();
    });
  }

  Repo get _repo => _ref.read(repoProvider);

  /// 초안 추가(저장 실패 시).
  Future<ConfirmationDraft> enqueue(Map<String, dynamic> body) async {
    final draft = ConfirmationDraft(
      id: 'draft_${DateTime.now().microsecondsSinceEpoch}',
      body: Map<String, dynamic>.from(body),
      createdAt: DateTime.now(),
    );
    state = [...state, draft];
    await _storage.save(state);
    return draft;
  }

  Future<void> remove(String id) async {
    state = state.where((d) => d.id != id).toList();
    await _storage.save(state);
  }

  /// 큐 전송 시도. 성공은 제거, 서버 검증 실패는 lastError 표시 후 유지,
  /// 네트워크 실패는 즉시 중단(아직 오프라인). 반환: (성공, 검증실패).
  Future<DraftFlushEvent?> flush() async {
    if (_flushing || state.isEmpty) return null;
    _flushing = true;
    var sent = 0;
    var failed = 0;
    try {
      // 스냅샷을 순회(전송 중 state 가 바뀔 수 있으므로).
      for (final draft in [...state]) {
        try {
          final created = await _repo.createConfirmation(draft.body);
          // 확인서 생성 성공 → 장부 반영됨. send 는 best-effort(실패해도 유지 안 함).
          try {
            await _repo.send(created.id);
          } on ApiException {
            // 전송(공유링크/알림)만 실패 — 확인서는 이미 저장됨.
          }
          await remove(draft.id);
          sent++;
        } on ApiException catch (e) {
          if (isRetriableFailure(e)) {
            // 아직 오프라인/서버 문제 — 큐 유지, 이후 재시도.
            break;
          }
          // 서버 검증 실패(400 등) — 초안에 사유 표시, 사용자 개입 유도.
          failed++;
          state = [
            for (final d in state)
              if (d.id == draft.id)
                d.copyWith(lastError: e.message, attempts: d.attempts + 1)
              else
                d
          ];
          await _storage.save(state);
        }
      }
    } finally {
      _flushing = false;
    }
    if (sent > 0) {
      // 홈/캘린더/장부 새로고침(WidgetRef 가 아닌 Ref 에서 직접 무효화).
      _ref.invalidate(confirmationsProvider);
      _ref.invalidate(ledgerSummaryProvider);
      _ref.invalidate(ledgerByCompanyProvider);
      _ref.invalidate(ledgerEntriesProvider);
      _ref.invalidate(expiringDocsProvider);
      _ref.invalidate(taxInvoiceDataProvider);
    }
    if (sent > 0 || failed > 0) {
      final ev = DraftFlushEvent(sent, failed);
      _ref.read(draftFlushEventProvider.notifier).state = ev;
      return ev;
    }
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final draftQueueProvider =
    StateNotifierProvider<DraftQueue, List<ConfirmationDraft>>(
        (ref) => DraftQueue(ref, ref.watch(draftStorageProvider)));

/// 폼 이탈 시 자동 보존되는 임시 초안 1건(작성 중 데이터).
class AutoDraftController extends StateNotifier<ConfirmationDraft?> {
  final DraftStorage _storage;
  AutoDraftController(this._storage) : super(null) {
    _load();
  }
  Future<void> _load() async {
    state = await _storage.loadAuto();
  }

  Future<void> save(Map<String, dynamic> body) async {
    final draft = ConfirmationDraft(
      id: 'auto',
      body: Map<String, dynamic>.from(body),
      createdAt: DateTime.now(),
    );
    state = draft;
    await _storage.saveAuto(draft);
  }

  Future<void> clear() async {
    state = null;
    await _storage.saveAuto(null);
  }
}

final autoDraftProvider =
    StateNotifierProvider<AutoDraftController, ConfirmationDraft?>(
        (ref) => AutoDraftController(ref.watch(draftStorageProvider)));
