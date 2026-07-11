import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';
import 'tbm_form_screen.dart';
import 'tbm_detail_screen.dart';

/// 사업장 TBM 기록 목록.
class TbmRecordsScreen extends ConsumerWidget {
  final String businessId;
  const TbmRecordsScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final records = ref.watch(bizTbmProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.tbmTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TbmFormScreen(businessId: businessId))),
        backgroundColor: c.primary,
        foregroundColor: c.primaryInk,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.tbmNew,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: records.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: c.primary)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorRetry(
                  boxed: false, onRetry: () => ref.invalidate(bizTbmProvider)),
            ),
          ),
          data: (list) => list.isEmpty
              ? _Empty()
              : RefreshIndicator(
                  color: c.primary,
                  onRefresh: () async => ref.invalidate(bizTbmProvider),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      for (final r in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TbmCard(
                            record: r,
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => TbmDetailScreen(
                                      id: r.id, businessId: businessId)));
                              ref.invalidate(bizTbmProvider);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 40, 18, 24),
      children: [
        PaperCard(
          stamp: l.tbmStamp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.tbmListEmptyTitle,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
              const SizedBox(height: 4),
              Text(l.tbmListEmptySub,
                  style: TextStyle(fontSize: 14, color: c.ink2, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

/// TBM 목록 카드 — 날짜/현장/위험요인 요약 + 참석·확인 카운트.
class TbmCard extends ConsumerWidget {
  final TbmRecord record;
  final VoidCallback onTap;
  const TbmCard({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety_outlined,
                      size: 20, color: c.accentText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(record.site,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.ink)),
                  ),
                  _AckPill(att: record.attendeeCount, ack: record.ackCount),
                ],
              ),
              const SizedBox(height: 6),
              Text(record.occurredAt,
                  style: TextStyle(
                      fontSize: 13,
                      color: c.ink2,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              if (record.hazardLabelsKo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(l.tbmAckSummary(record.attendeeCount, record.ackCount),
                    style: TextStyle(fontSize: 12.5, color: c.ink3)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AckPill extends StatelessWidget {
  final int att;
  final int ack;
  const _AckPill({required this.att, required this.ack});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final done = att > 0 && ack >= att;
    final bg = done ? c.deposited.withValues(alpha: 0.12) : c.primary.withValues(alpha: 0.12);
    final fg = done ? c.depositedBadge : c.accentText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(done ? Icons.verified_rounded : Icons.people_alt_outlined,
            size: 13, color: fg),
        const SizedBox(width: 4),
        Text('$ack/$att',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}
