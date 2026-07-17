import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../widgets/common.dart';

/// 사업장 홈 최상단 카드 — 오늘 현장별 인원 요약(전체/출근/완료/미출근).
/// 탭하면 현장·작업자별 상세로 이동. 데이터 없거나 로딩 실패면 조용히 숨김.
class AttendanceBoardCard extends ConsumerWidget {
  const AttendanceBoardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final board = ref.watch(todayAttendanceProvider);
    final data = board.valueOrNull;
    if (data == null) return const SizedBox.shrink();
    final s = data.summary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AttendanceBoardScreen())),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.how_to_reg_outlined,
                        size: 20, color: c.accentText),
                    const SizedBox(width: 8),
                    Text(l.attendBoardTitle,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.ink)),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: c.ink3),
                  ],
                ),
                const SizedBox(height: 12),
                if (s.total == 0)
                  Text(l.attendBoardEmpty,
                      style: TextStyle(fontSize: 14, color: c.ink2))
                else ...[
                  Row(
                    children: [
                      _SummaryTile(
                          label: l.attendSummaryTotal,
                          value: s.total,
                          color: c.ink),
                      _SummaryTile(
                          label: l.attendSummaryAttended,
                          value: s.attended,
                          color: c.primary),
                      _SummaryTile(
                          label: l.attendSummaryCompleted,
                          value: s.completed,
                          color: c.deposited),
                      _SummaryTile(
                          label: l.attendSummaryAbsent,
                          value: s.absent,
                          color: s.absent > 0 ? c.receivable : c.ink3),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(l.attendBoardViewDetail,
                      style: TextStyle(fontSize: 12.5, color: c.ink3)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryTile(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12.5, color: c.ink2)),
        ],
      ),
    );
  }
}

/// 출역 현황 상세 — 현장별 그룹 + 작업자별 상태·시작 시각·컨디션 배지.
/// 당겨서 새로고침.
class AttendanceBoardScreen extends ConsumerWidget {
  const AttendanceBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final board = ref.watch(todayAttendanceProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.attendBoardTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          color: c.primary,
          onRefresh: () async {
            ref.invalidate(todayAttendanceProvider);
            try {
              await ref.read(todayAttendanceProvider.future);
            } catch (_) {}
          },
          child: board.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: c.primary)),
            error: (e, _) => ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  child: ErrorRetry(
                      onRetry: () =>
                          ref.invalidate(todayAttendanceProvider)),
                ),
              ],
            ),
            data: (d) => d.sites.isEmpty
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                            child: Text(l.attendBoardEmpty,
                                style: TextStyle(
                                    fontSize: 15, color: c.ink2))),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _OverallSummary(summary: d.summary),
                      for (final site in d.sites) _SiteGroup(site: site),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _OverallSummary extends StatelessWidget {
  final AttendanceSummary summary;
  const _OverallSummary({required this.summary});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _SummaryTile(
              label: l.attendSummaryTotal, value: summary.total, color: c.ink),
          _SummaryTile(
              label: l.attendSummaryAttended,
              value: summary.attended,
              color: c.primary),
          _SummaryTile(
              label: l.attendSummaryCompleted,
              value: summary.completed,
              color: c.deposited),
          _SummaryTile(
              label: l.attendSummaryAbsent,
              value: summary.absent,
              color: summary.absent > 0 ? c.receivable : c.ink3),
        ],
      ),
    );
  }
}

class _SiteGroup extends StatelessWidget {
  final AttendanceSite site;
  const _SiteGroup({required this.site});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 17, color: c.accentText),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(site.site,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.ink)),
                ),
                Text(
                    '${l.attendPeopleCount(site.summary.total)} · ${l.attendSummaryCompleted} ${site.summary.completed}',
                    style: TextStyle(fontSize: 12.5, color: c.ink3)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (var i = 0; i < site.workers.length; i++)
                  _WorkerRow(
                      w: site.workers[i],
                      last: i == site.workers.length - 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerRow extends StatelessWidget {
  final AttendanceWorker w;
  final bool last;
  const _WorkerRow({required this.w, required this.last});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    // 시간 라인: 시작했으면 시작 시각, 아니면 예정 시각.
    final String timeLine;
    if (w.startedAt != null && w.startedAt!.isNotEmpty) {
      timeLine = l.attendStartedAt(w.startedAt!);
    } else {
      timeLine = l.attendScheduledAt(w.scheduledAt);
    }
    return Container(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(w.workerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.ink)),
                    ),
                    if (w.condition == 'BAD') ...[
                      const SizedBox(width: 8),
                      _CondBadge(ok: false),
                    ] else if (w.condition == 'OK') ...[
                      const SizedBox(width: 8),
                      _CondBadge(ok: true),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(timeLine,
                    style: TextStyle(
                        fontSize: 13,
                        color: c.ink2,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusBadge(status: w.status),
        ],
      ),
    );
  }
}

class _CondBadge extends StatelessWidget {
  final bool ok;
  const _CondBadge({required this.ok});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final color = ok ? c.deposited : c.warnInk;
    final bg = ok ? c.deposited.withValues(alpha: 0.12) : c.warnBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: ok ? null : Border.all(color: c.warnBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              ok
                  ? Icons.sentiment_satisfied_alt_rounded
                  : Icons.sentiment_dissatisfied_rounded,
              size: 12,
              color: color),
          const SizedBox(width: 3),
          Text(ok ? l.attendCondOk : l.attendCondBad,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    Color fg;
    String label;
    switch (status) {
      case 'DONE':
        fg = c.depositedBadge;
        label = l.attendStatusDone;
        break;
      case 'STARTED':
        fg = c.accentText;
        label = l.attendStatusStarted;
        break;
      case 'ACCEPTED':
        fg = c.ink2;
        label = l.attendStatusAccepted;
        break;
      case 'CANCELLED':
        fg = c.ink3;
        label = l.attendStatusCancelled;
        break;
      default:
        fg = c.ink3;
        label = l.attendStatusScheduled;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

/// 위젯 테스트에서 요약 매핑(요약 카운트 → 화면 표시)이 일치하는지 확인하는 헬퍼.
/// 순서: [전체, 출근, 완료, 미출근].
List<int> attendanceSummaryCounts(AttendanceSummary s) =>
    [s.total, s.attended, s.completed, s.absent];
