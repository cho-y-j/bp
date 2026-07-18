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
    final byDate = list.byDateMap;
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
                  Text(formatMoney(list.totalAmount, context.lang),
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
            childAspectRatio: 0.68,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: cells.length,
          itemBuilder: (_, i) {
            final day = cells[i];
            if (day == null) return const SizedBox.shrink();
            final key = dateParam(day);
            final agg = byDate[key];
            final isToday = day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;
            return _DayCell(
              key: ValueKey('cal-day-$key'),
              day: day,
              agg: agg,
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

class _DayCell extends StatelessWidget {
  final DateTime day;
  final DayAggregate? agg;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;
  const _DayCell(
      {super.key,
      required this.day,
      required this.agg,
      required this.isToday,
      required this.isSelected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasWork = agg != null && agg!.count > 0;
    final borderColor = isSelected
        ? c.primary
        : (isToday ? c.primary : c.border);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? c.primary.withValues(alpha: 0.16)
              : (hasWork ? c.primary.withValues(alpha: 0.07) : c.surface),
          border: Border.all(
              color: borderColor, width: (isSelected || isToday) ? 1.6 : 1),
          borderRadius: BorderRadius.circular(9),
        ),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Column(
          children: [
            Text('${day.day}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        (isToday || isSelected) ? FontWeight.w800 : FontWeight.w600,
                    color: (isToday || isSelected) ? c.accentText : c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 3),
            if (hasWork) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                    _compact(agg!.totalAmount, context.lang, context.l.calManUnit),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: c.accentText,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 셀 안 좁은 폭용 축약 금액. CJK(ko/zh)는 만/万 단위(÷10000),
  // 그 외 언어는 천 단위(÷1000)로 축약하고 단위 라벨(calManUnit)을 붙인다.
  static String _compact(int won, String lang, String unit) {
    final cjk = lang == 'ko' || lang == 'zh';
    final div = cjk ? 10000 : 1000;
    if (won >= div) {
      final u = won / div;
      final s = u == u.roundToDouble() ? '${u.round()}' : u.toStringAsFixed(1);
      return '$s$unit';
    }
    return '$won';
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
                        color: c.receivable,
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
                          color: c.receivable,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
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

