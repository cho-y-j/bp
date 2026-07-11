import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../core/draft_store.dart';
import '../../providers/drafts.dart';
import '../../widgets/common.dart';

/// 오프라인 임시저장 초안 목록 — 수동 재시도(전송)·삭제.
class DraftListScreen extends ConsumerStatefulWidget {
  const DraftListScreen({super.key});
  @override
  ConsumerState<DraftListScreen> createState() => _DraftListScreenState();
}

class _DraftListScreenState extends ConsumerState<DraftListScreen> {
  bool _retrying = false;

  Future<void> _retryAll() async {
    setState(() => _retrying = true);
    final messenger = ScaffoldMessenger.of(context);
    final ev = await ref.read(draftQueueProvider.notifier).flush();
    if (!mounted) return;
    setState(() => _retrying = false);
    if (ev == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('아직 전송하지 못했어요. 연결을 확인해 주세요.')));
    } else if (ev.sent > 0) {
      messenger.showSnackBar(
          SnackBar(content: Text('${ev.sent}건 전송 완료 · 장부에 반영되었어요.')));
    } else {
      messenger.showSnackBar(
          const SnackBar(content: Text('전송에 실패한 초안이 있어요. 내용을 확인해 주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final drafts = ref.watch(draftQueueProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('임시저장 초안')),
      body: drafts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_outlined, size: 44, color: c.ink3),
                    const SizedBox(height: 12),
                    Text('전송 대기 중인 초안이 없어요.',
                        style: TextStyle(fontSize: 16, color: c.ink2)),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
                        child: Text(
                            '연결이 복구되면 자동으로 전송돼요. 지금 바로 보내려면 아래에서 다시 시도하세요.',
                            style: TextStyle(fontSize: 13.5, color: c.ink2)),
                      ),
                      for (final d in drafts) _DraftCard(draft: d),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border(top: BorderSide(color: c.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SafeArea(
                    top: false,
                    child: PrimaryButton(
                      label: '지금 모두 전송',
                      icon: Icons.cloud_upload_outlined,
                      loading: _retrying,
                      onPressed: _retryAll,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DraftCard extends ConsumerWidget {
  final ConfirmationDraft draft;
  const _DraftCard({required this.draft});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final rate = (draft.body['rate'] as num?)?.round() ?? 0;
    final qty = draft.body['quantity'];
    final isGongsu = draft.body['rateType'] == 'GONGSU';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(
            color: draft.lastError != null ? c.warnBorder : c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft.siteName.isEmpty ? '(현장 미입력)' : draft.siteName,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                const SizedBox(height: 2),
                Text(
                    '${draft.date} · ${draft.companyName}'
                    '${rate > 0 ? ' · ${formatWon(rate)}${isGongsu && qty is num ? ' × ${formatGongsu(qty)}공수' : ''}' : ''}',
                    style: TextStyle(fontSize: 13, color: c.ink2)),
                if (draft.lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('확인 필요: ${draft.lastError}',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: c.warnInk)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: c.ink3),
            onPressed: () => ref.read(draftQueueProvider.notifier).remove(draft.id),
          ),
        ],
      ),
    );
  }
}
