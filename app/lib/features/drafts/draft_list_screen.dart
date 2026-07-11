import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../core/draft_store.dart';
import '../../l10n/l10n_ext.dart';
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
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    final ev = await ref.read(draftQueueProvider.notifier).flush();
    if (!mounted) return;
    setState(() => _retrying = false);
    if (ev == null) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.draftFlushNone)));
    } else if (ev.sent > 0) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.draftFlushSent(ev.sent))));
    } else {
      messenger.showSnackBar(
          SnackBar(content: Text(l.draftFlushFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final drafts = ref.watch(draftQueueProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.draftTitle)),
      body: drafts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_outlined, size: 44, color: c.ink3),
                    const SizedBox(height: 12),
                    Text(l.draftEmpty,
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
                            l.draftHint,
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
                      label: l.draftSendAll,
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
    final l = context.l;
    final lang = context.lang;
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
                Text(draft.siteName.isEmpty ? l.draftNoSite : draft.siteName,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                const SizedBox(height: 2),
                Text(
                    '${draft.date} · ${draft.companyName}'
                    '${rate > 0 ? ' · ${formatMoney(rate, lang)}${isGongsu && qty is num ? ' × ${l.qtyGongsu(formatGongsu(qty))}' : ''}' : ''}',
                    style: TextStyle(fontSize: 13, color: c.ink2)),
                if (draft.lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(l.draftCheckNeeded('${draft.lastError}'),
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
