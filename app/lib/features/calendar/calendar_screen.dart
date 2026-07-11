import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../confirmation/confirmation_form_screen.dart';
import '../confirmation/confirmation_detail_screen.dart';

final _calViewProvider = StateProvider<bool>((ref) => true); // true=월간 그리드, false=주간 리스트

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
                    ref.read(selectedMonthProvider.notifier).state =
                        DateTime(month.year, month.month - 1);
                  }),
                  Text(formatMonthK(month),
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
                  _monthNav(context, Icons.chevron_right_rounded, () {
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
        seg(true, Icons.calendar_view_month_rounded, '월'),
        seg(false, Icons.view_agenda_outlined, '주'),
      ]),
    );
  }
}

// ── 월간 그리드 ───────────────────────────────────────────────
class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final ConfirmationList list;
  const _MonthGrid({required this.month, required this.list});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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

    const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    final today = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 24),
      children: [
        // 월 합계
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Row(
            children: [
              Text('작업 ${list.count}건',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: c.ink2)),
              const Spacer(),
              Text(formatWonUnit(list.totalAmount),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()])),
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
              day: day,
              agg: agg,
              isToday: isToday,
              onTap: () => _openDay(context, day, list),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final DayAggregate? agg;
  final bool isToday;
  final VoidCallback onTap;
  const _DayCell(
      {required this.day, required this.agg, required this.isToday, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasWork = agg != null && agg!.count > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasWork ? c.primary.withValues(alpha: 0.07) : c.surface,
          border: Border.all(
              color: isToday ? c.primary : c.border, width: isToday ? 1.6 : 1),
          borderRadius: BorderRadius.circular(9),
        ),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Column(
          children: [
            Text('${day.day}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: isToday ? c.accentText : c.ink,
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
                child: Text(_compact(agg!.totalAmount),
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

  static String _compact(int won) {
    if (won >= 10000) {
      final man = won / 10000;
      return man == man.roundToDouble()
          ? '${man.round()}만'
          : '${man.toStringAsFixed(1)}만';
    }
    return '$won';
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
          child: Text('이 달에 기록된 작업이 없어요.',
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
                  Text(formatShortDate(date),
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800, color: c.ink)),
                  const Spacer(),
                  Text(formatWonUnit(dayTotal),
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
                    Text(conf.siteName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                    const SizedBox(height: 2),
                    Text(
                        '${conf.companyName} · ${ampm(conf.startTime)}~${ampm(conf.endTime)}'
                        '${conf.baseUnit != null ? ' · ${formatGongsu(conf.baseQuantity)}${conf.baseUnit}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.ink2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(formatWon(conf.total),
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

// 날짜 탭 → 해당일 기록 시트
void _openDay(BuildContext context, DateTime day, ConfirmationList list) {
  final confs = list.items.where((x) => x.date == dateParam(day)).toList();
  showModalBottomSheet(
    context: context,
    backgroundColor: context.c.bg,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      final c = ctx.c;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: c.borderStrong, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Text(formatDateK(day),
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: 12),
              if (confs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('이 날 기록된 작업이 없어요.',
                      style: TextStyle(fontSize: 15, color: c.ink2)),
                )
              else
                ...confs.map((conf) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _WeekItem(conf: conf),
                    )),
              const SizedBox(height: 8),
              PrimaryButton(
                label: '이 날 작업 기록하기',
                icon: Icons.add_rounded,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ConfirmationFormScreen(initialDate: day),
                    fullscreenDialog: true,
                  ));
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
