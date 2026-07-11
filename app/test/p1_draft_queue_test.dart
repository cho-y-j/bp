import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workon/core/api_client.dart';
import 'package:workon/core/draft_store.dart';
import 'package:workon/models/models.dart';
import 'package:workon/providers/data.dart';
import 'package:workon/providers/drafts.dart';

/// 메모리 기반 초안 저장소(테스트용).
class _MemStorage implements DraftStorage {
  List<ConfirmationDraft> queue = [];
  ConfirmationDraft? auto;
  @override
  Future<List<ConfirmationDraft>> load() async => queue;
  @override
  Future<void> save(List<ConfirmationDraft> drafts) async => queue = drafts;
  @override
  Future<ConfirmationDraft?> loadAuto() async => auto;
  @override
  Future<void> saveAuto(ConfirmationDraft? draft) async => auto = draft;
}

/// 시나리오를 제어하는 가짜 Repo.
class _FakeRepo extends Repo {
  bool networkDown = false;
  final bool validationError;
  int createdCount = 0;
  _FakeRepo({this.validationError = false}) : super(ApiClient());
  @override
  Future<Confirmation> createConfirmation(Map<String, dynamic> body) async {
    if (networkDown) throw ApiException('NETWORK', '서버에 연결할 수 없습니다.');
    if (validationError) {
      throw ApiException('INVALID_GONGSU_QUANTITY', '공수는 0.1 단위입니다.', 400);
    }
    createdCount++;
    return Confirmation.fromJson({
      'id': 'srv_$createdCount',
      'status': 'DRAFT',
      'date': body['date'],
      'siteName': body['siteName'],
      'rateType': body['rateType'],
      'total': 0,
    });
  }

  @override
  Future<Map> send(String id) async => {'linked': false, 'url': ''};
}

ConfirmationDraft _draft(String id) => ConfirmationDraft(
      id: id,
      body: {'date': '2026-07-11', 'siteName': '현장$id', 'rateType': 'DAILY'},
      createdAt: DateTime(2026, 7, 11),
    );

void main() {
  group('초안 직렬화 — encodeList/decodeList 라운드트립', () {
    test('공수 본문 포함 직렬화 후 복원', () {
      final drafts = [
        ConfirmationDraft(
          id: 'draft_1',
          body: {
            'date': '2026-07-11',
            'siteName': '래미안',
            'rateType': 'GONGSU',
            'rate': 180000,
            'quantity': 1.5,
          },
          createdAt: DateTime(2026, 7, 11, 9, 30),
          lastError: '검증 실패',
          attempts: 2,
        ),
      ];
      final restored = ConfirmationDraft.decodeList(
          ConfirmationDraft.encodeList(drafts));
      expect(restored.length, 1);
      final d = restored.first;
      expect(d.id, 'draft_1');
      expect(d.body['rateType'], 'GONGSU');
      expect(d.body['quantity'], 1.5);
      expect(d.lastError, '검증 실패');
      expect(d.attempts, 2);
      expect(d.siteName, '래미안');
    });

    test('빈/깨진 입력은 빈 리스트', () {
      expect(ConfirmationDraft.decodeList(null), isEmpty);
      expect(ConfirmationDraft.decodeList(''), isEmpty);
      expect(ConfirmationDraft.decodeList('{not json'), isEmpty);
    });
  });

  group('재시도 대상 분류 — isRetriableFailure', () {
    test('네트워크/타임아웃/5xx 는 재시도(큐 유지)', () {
      expect(isRetriableFailure(ApiException('NETWORK', '')), isTrue);
      expect(isRetriableFailure(ApiException('HTTP_503', '', 503)), isTrue);
      expect(isRetriableFailure(ApiException('X', '', null)), isTrue);
    });
    test('4xx 검증 오류는 초안 유도(재시도 아님)', () {
      expect(isRetriableFailure(ApiException('INVALID_GONGSU_QUANTITY', '', 400)),
          isFalse);
      expect(isRetriableFailure(ApiException('BAD', '', 422)), isFalse);
    });
  });

  group('DraftQueue flush 로직', () {
    late _MemStorage storage;
    late _FakeRepo repo;
    late ProviderContainer container;

    ProviderContainer make() => ProviderContainer(overrides: [
          draftStorageProvider.overrideWithValue(storage),
          repoProvider.overrideWithValue(repo),
          connectivityStreamProvider.overrideWithValue(
              const Stream<List<ConnectivityResult>>.empty()),
        ]);

    setUp(() {
      storage = _MemStorage();
      repo = _FakeRepo();
    });

    tearDown(() => container.dispose());

    test('enqueue → 저장소에 반영', () async {
      container = make();
      final q = container.read(draftQueueProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await q.enqueue({'siteName': 'A', 'rateType': 'DAILY'});
      expect(container.read(draftQueueProvider).length, 1);
      expect(storage.queue.length, 1);
    });

    test('오프라인 flush → 큐 유지', () async {
      repo.networkDown = true;
      storage.queue = [_draft('1'), _draft('2')];
      container = make();
      final q = container.read(draftQueueProvider.notifier);
      // 초기 로드 완료 대기
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final ev = await q.flush();
      expect(ev, isNull); // 아무것도 못 보냄
      expect(container.read(draftQueueProvider).length, 2);
    });

    test('온라인 flush → 전송 후 큐 제거 + 이벤트', () async {
      storage.queue = [_draft('1'), _draft('2')];
      container = make();
      final q = container.read(draftQueueProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final ev = await q.flush();
      expect(ev, isNotNull);
      expect(ev!.sent, 2);
      expect(ev.failed, 0);
      expect(container.read(draftQueueProvider), isEmpty);
      expect(repo.createdCount, 2);
    });

    test('서버 검증 실패 → 초안 유지 + lastError 표시', () async {
      repo = _FakeRepo(validationError: true);
      storage.queue = [_draft('1')];
      container = make();
      final q = container.read(draftQueueProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final ev = await q.flush();
      expect(ev!.sent, 0);
      expect(ev.failed, 1);
      final remaining = container.read(draftQueueProvider);
      expect(remaining.length, 1);
      expect(remaining.first.lastError, isNotNull);
      expect(remaining.first.attempts, 1);
    });
  });
}
