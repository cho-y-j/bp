import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../confirmation/confirmation_form_screen.dart';
import '../confirmation/confirmation_detail_screen.dart';

final _calViewProvider = StateProvider<bool>((ref) => true); // true=월간 그리드, false=주간 리스트
// 월 그리드에서 펼쳐 볼(장부) 선택 날짜. null이면 접힘.
final _selectedDayProvider = StateProvider<DateTime?>((ref) => null);

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final month = ref.watch(selectedMonthProvider);
    final isGrid = ref.watch(_calViewProvider);
    final data = ref.watch(confirmationsProvider(monthParam(month)));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 헤더: 월 네비 + 뷰 토글
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
              child: Row(
                children: [
                  _monthNav(context, Icons.chevron_left_rounded, () {
                    ref.read(_selectedDayProvider.notifier).state = null;
                    ref.read(selectedMonthProvider.notifier).state =
                        DateTime(month.year, month.month - 1);
                  }),
                  Text(fmtMonth(month, context.lang),
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
                  _monthNav(context, Icons.chevron_right_rounded, () {
                    ref.read(_selectedDayProvider.notifier).state = null;
                    ref.read(selectedMonthProvider.notifier).state =
                        DateTime(month.year, month.month + 1);
                  }),
                  const Spacer(),
                  _ViewToggle(
                    isGrid: isGrid,
                    onChanged: (v) => ref.read(_calViewProvider.notifier).state = v,
                  ),
                ],
              ),
            ),
            Expanded(
              child: data.when(
                loading: () => Center(
                    child: CircularProgressIndicator(color: c.primary)),
                error: (e, _) => Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ErrorRetry(
                            boxed: false,
                            onRetry: () =>
                                ref.invalidate(confirmationsProvider)))),
                data: (list) => isGrid
                    ? _MonthGrid(month: month, list: list)
                    : _WeekList(month: month, list: list),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthNav(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: SizedBox(
          width: 44, height: 44, child: Icon(icon, color: context.c.ink3)),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.isGrid, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget seg(bool grid, IconData icon, String label) {
      final on = isGrid == grid;
      return GestureDetector(
        onTap: () => onChanged(grid),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: on ? c.primary.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(children: [
            Icon(icon, size: 16, color: on ? c.accentText : c.ink3),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: on ? c.accentText : c.ink3)),
          ]),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(children: [
        seg(true, Icons.calendar_view_month_rounded, context.l.calViewMonth),
        seg(false, Icons.view_agenda_outlined, context.l.calViewWeek),
      ]),
    );
  }
}

// ── 월간 그리드(장부) ─────────────────────────────────────────
// 날짜를 누르면 그 아래로 그날 확인서 목록이 펼쳐진다(장부 뷰).
class _MonthGrid extends ConsumerWidget {
  final DateTime month;
  final ConfirmationList list;
  const _MonthGrid({required this.month, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final selected = ref.watch(_selectedDayProvider);
    // 날짜별 확인서(일감 미니 라인용) — 구글 캘린더 월뷰처럼 칸 안에 줄로 표시.
    final byDayConfs = <String, List<Confirmation>>{};
    for (final it in list.items) {
      byDayConfs.putIfAbsent(it.date, () => []).add(it);
    }
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // 주 시작을 일요일로: weekday Mon=1..Sun=7 → 일요일 index=0
    final lead = first.weekday == 7 ? 0 : first.weekday;
    final cells = <DateTime?>[];
    for (var i = 0; i < lead; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(month.year, month.month, d));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final loc = localeName(context.lang);
    final weekdayLabels = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(loc).format(DateTime(2024, 1, 7 + i)), // 2024-01-07 = 일요일
    ];
    final today = DateTime.now();
    final selKey = selected == null ? null : dateParam(selected);

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 24),
      children: [
        // 월 합계 — 그 달 받을 돈(홈 히어로와 동일 서식: 미수 색·큰 숫자).
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.calMonthReceivable,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.ink2)),
                  const SizedBox(height: 2),
                  // '받을 돈' = 미수 합(totalOutstanding). 홈 히어로(ledger summary)와
                  // 동일 정의 — 서버가 확인서 연결 장부 기준으로 동일하게 집계한다.
                  Text(formatMoney(list.totalOutstanding, context.lang),
                      style: TextStyle(
                          fontSize: 26,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: c.receivable,
                          letterSpacing: -0.3,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(l.calWorkCount(list.count),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.ink3)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(weekdayLabels[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: i == 0
                              ? c.receivable
                              : (i == 6 ? c.accentText : c.ink3))),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            // 칸 안에 일감 미니 라인(최대 3줄)을 담기 위해 셀을 세로로 늘림.
            // 6주(42칸) 달도 히어로/요일행 포함 한 화면에 들어오는 비율.
            childAspectRatio: 0.60,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: cells.length,
          itemBuilder: (_, i) {
            final day = cells[i];
            if (day == null) return const SizedBox.shrink();
            final key = dateParam(day);
            final isToday = day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;
            return _DayCell(
              key: ValueKey('cal-day-$key'),
              day: day,
              confs: byDayConfs[key] ?? const [],
              isToday: isToday,
              isSelected: selKey == key,
              onTap: () {
                // 같은 날 다시 누르면 접기(토글).
                ref.read(_selectedDayProvider.notifier).state =
                    selKey == key ? null : day;
              },
            );
          },
        ),
        // 선택 날짜 장부 패널(펼침) / 미선택 시 안내.
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 14, 2, 0),
            child: _DayLedger(day: selected, list: list),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined, size: 15, color: c.ink3),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(l.calTapDayHint,
                      style: TextStyle(fontSize: 13, color: c.ink3)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// 미니 라인 상태 구분: 입금완료(초록) / 미수(주황) / 초안·전송(중립 회색).
enum _LineKind { paid, due, draft }

_LineKind _lineKindOf(Confirmation c) {
  // DRAFT/SENT 는 아직 서명 전(확정 미수 아님) → 중립 회색.
  if (c.status == 'DRAFT' || c.status == 'SENT') return _LineKind.draft;
  // SIGNED: 완납이면 입금(초록), 미수 잔존이면 미수(주황).
  return c.isFullyPaid ? _LineKind.paid : _LineKind.due;
}

// 구글 캘린더 월뷰처럼 날짜 칸 안에 그날 일감을 미니 라인(최대 3줄)으로 표시.
//  - 각 줄 = 현장명(말줄임 1줄) + 정산 상태 색 칩.
//  - 3건 초과분은 마지막 줄을 "+N".
//  - 금액은 칸에서 생략(무슨 일을 했는지 우선) — 합계·건별 금액은 탭 펼침 뷰에서.
class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<Confirmation> confs;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;
  const _DayCell(
      {super.key,
      required this.day,
      required this.confs,
      required this.isToday,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasWork = confs.isNotEmpty;
    final borderColor = isSelected || isToday ? c.primary : c.border;

    // 최대 3줄: 3건 이하면 전부, 초과면 2줄 + "+N".
    const maxLines = 3;
    final total = confs.length;
    final shown = total <= maxLines ? total : maxLines - 1;
    final overflow = total - shown;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? c.primary.withValues(alpha: 0.12)
              : c.surface,
          border: Border.all(
              color: borderColor, width: (isSelected || isToday) ? 1.6 : 1),
          borderRadius: BorderRadius.circular(9),
        ),
        padding: const EdgeInsets.fromLTRB(3, 4, 3, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 1, bottom: 2),
              child: Text('${day.day}',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.0,
                      fontWeight: (isToday || isSelected)
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: (isToday || isSelected) ? c.accentText : c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            if (hasWork) ...[
              for (var i = 0; i < shown; i++) _line(context, confs[i]),
              if (overflow > 0) _plusLine(context, overflow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, Confirmation conf) {
    final c = context.c;
    late final Color bg, fg;
    switch (_lineKindOf(conf)) {
      case _LineKind.paid:
        bg = c.deposited.withValues(alpha: 0.16);
        fg = c.depositedBadge;
        break;
      case _LineKind.due:
        bg = c.receivable.withValues(alpha: 0.15);
        fg = c.receivable;
        break;
      case _LineKind.draft:
        bg = c.ink2.withValues(alpha: 0.10);
        fg = c.ink2;
        break;
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(conf.siteName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
              fontSize: 9,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }

  Widget _plusLine(BuildContext context, int n) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 1),
      child: Text('+$n',
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800, color: c.ink3)),
    );
  }
}

// ── 선택 날짜 장부 패널(그리드 아래 펼침) ──────────────────────
class _DayLedger extends StatelessWidget {
  final DateTime day;
  final ConfirmationList list;
  const _DayLedger({required this.day, required this.list});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final confs = list.items.where((x) => x.date == dateParam(day)).toList();
    final dayTotal = confs.fold<int>(0, (s, x) => s + x.total);
    // 그날 모든 확인서가 완납이면 합계도 입금 색(초록), 미수 잔존이면 미수 색(주황).
    final dayFullyPaid =
        confs.isNotEmpty && confs.every((x) => x.isFullyPaid);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.borderStrong),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 + 그날 합계(받을 돈 색).
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(fmtDate(day, context.lang),
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: c.ink)),
              ),
              if (confs.isNotEmpty)
                Text(formatMoney(dayTotal, context.lang),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: dayFullyPaid ? c.depositedBadge : c.receivable,
                        fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
          const SizedBox(height: 12),
          if (confs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(l.calEmptyDay,
                  style: TextStyle(fontSize: 15, color: c.ink2)),
            )
          else
            for (final conf in confs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DayLedgerRow(conf: conf),
              ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: l.calRecordThisDay,
            icon: Icons.add_rounded,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ConfirmationFormScreen(initialDate: day),
              fullscreenDialog: true,
            )),
          ),
        ],
      ),
    );
  }
}

// 장부 행: 현장명·상대·시간 + 상태 배지 + 큰 금액. 탭 → 확인서 상세.
class _DayLedgerRow extends StatelessWidget {
  final Confirmation conf;
  const _DayLedgerRow({required this.conf});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final st = conf.settlement;
    // 항목 금액 색: 완납이면 입금(초록), 아니면 미수(주황).
    final amtColor = conf.isFullyPaid ? c.depositedBadge : c.receivable;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ConfirmationDetailScreen(confirmationId: conf.id))),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(conf.siteName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.ink)),
                  ),
                  const SizedBox(width: 8),
                  Text(formatMoney(conf.total, context.lang),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: amtColor,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
              // 부분입금(PARTIAL): '입금 N원' 보조 표기 한 줄(입금 색).
              if (st != null && st.isPartial) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                      context.l.ledgerDeposited(
                          formatMoney(st.paidAmount, context.lang)),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.depositedBadge,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  if (conf.isTeam) ...[
                    const TeamBadge(),
                    const SizedBox(width: 6),
                  ],
                  _StatusChip(status: conf.status, label: conf.statusLabel),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        '${conf.companyName} · ${fmtAmpm(conf.startTime, context.lang)}~${fmtAmpm(conf.endTime, context.lang)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.ink2)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 확인서 상태 칩(작성됨/전송됨/서명완료 등 — 백엔드 라벨 사용).
class _StatusChip extends StatelessWidget {
  final String status;
  final String label;
  const _StatusChip({required this.status, required this.label});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (label.isEmpty) return const SizedBox.shrink();
    late final Color bg, fg;
    if (status == 'SIGNED') {
      bg = c.deposited.withValues(alpha: 0.12);
      fg = c.depositedBadge;
    } else if (status == 'SENT') {
      bg = c.primary.withValues(alpha: 0.12);
      fg = c.accentText;
    } else {
      bg = c.ink2.withValues(alpha: 0.10);
      fg = c.ink2;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

// ── 주간 리스트 ───────────────────────────────────────────────
class _WeekList extends StatelessWidget {
  final DateTime month;
  final ConfirmationList list;
  const _WeekList({required this.month, required this.list});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // 작업 있는 날짜만 그룹핑 (날짜 오름차순)
    final byDay = <String, List<Confirmation>>{};
    for (final conf in list.items) {
      byDay.putIfAbsent(conf.date, () => []).add(conf);
    }
    final days = byDay.keys.toList()..sort();
    if (days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(context.l.calEmptyMonth,
              style: TextStyle(fontSize: 16, color: c.ink2)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final date = DateTime.parse(days[i]);
        final confs = byDay[days[i]]!;
        final dayTotal = confs.fold<int>(0, (s, x) => s + x.total);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
              child: Row(
                children: [
                  Text(fmtShortDate(date, context.lang),
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: c.ink)),
                  const Spacer(),
                  Text(formatMoney(dayTotal, context.lang),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: c.accentText,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
            for (final conf in confs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _WeekItem(conf: conf),
              ),
          ],
        );
      },
    );
  }
}

class _WeekItem extends StatelessWidget {
  final Confirmation conf;
  const _WeekItem({required this.conf});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ConfirmationDetailScreen(confirmationId: conf.id))),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(conf.siteName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.ink)),
                      ),
                      if (conf.isTeam) ...[
                        const SizedBox(width: 6),
                        const TeamBadge(),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                        '${conf.companyName} · ${fmtAmpm(conf.startTime, context.lang)}~${fmtAmpm(conf.endTime, context.lang)}'
                        '${conf.baseUnit != null ? ' · ${conf.baseUnit == '공수' ? context.l.qtyGongsu(formatGongsu(conf.baseQuantity)) : '${formatGongsu(conf.baseQuantity)}${conf.baseUnit}'}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.ink2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(formatMoney(conf.total, context.lang),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ),
      ),
    );
  }
}

