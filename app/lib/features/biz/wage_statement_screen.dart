import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../widgets/common.dart';

/// 지급명세서 세액 요약 한 줄(원천징수 합계 · 차인지급액).
/// 순수 함수 — 위젯 테스트에서 세액 표시 포맷을 검증한다. (금액 tabular)
String wageWithholdingSummary(
    AppLocalizations l, WageTax tax, String lang) {
  return '${l.wageStmtTotalTax} ${formatMoney(tax.totalTax, lang)}'
      ' · ${l.wageStmtNetPay} ${formatMoney(tax.netPay, lang)}';
}

/// 사업장 메뉴 "지급명세서(월 마감)" — 월 선택 → 작업자별 지급액·일수 +
/// 소득유형 토글(사업소득 3.3% ↔ 일용근로) 세액·차인지급액 → 복사 → 월 마감.
class WageStatementScreen extends ConsumerStatefulWidget {
  const WageStatementScreen({super.key});
  @override
  ConsumerState<WageStatementScreen> createState() =>
      _WageStatementScreenState();
}

class _WageStatementScreenState extends ConsumerState<WageStatementScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _daily = false; // false=사업소득 3.3%, true=일용근로
  bool _marking = false;

  Future<void> _copy(WageStatement w) async {
    await Clipboard.setData(ClipboardData(text: w.copyText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l.wageStmtCopied)));
  }

  Future<void> _mark(String month) async {
    setState(() => _marking = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    try {
      final already =
          await ref.read(bizRepoProvider).markWageStatement(month);
      ref.invalidate(wageStatementProvider(month));
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(
              already ? l.wageStmtAlreadyMarked : l.wageStmtMarkedSnack(month))));
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(l.wageStmtMarkFail(e.message))));
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final month = monthParam(_month);
    final stmt = ref.watch(wageStatementProvider(month));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.wageStmtTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          color: c.primary,
          onRefresh: () async {
            ref.invalidate(wageStatementProvider(month));
            try {
              await ref.read(wageStatementProvider(month).future);
            } catch (_) {}
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _MonthSelector(
                month: _month,
                onPrev: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1)),
                onNext: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1)),
              ),
              const SizedBox(height: 6),
              stmt.when(
                loading: () => const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: ErrorRetry(
                        onRetry: () =>
                            ref.invalidate(wageStatementProvider(month)))),
                data: (w) => w.workers.isEmpty
                    ? _empty(context, w)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TypeToggle(
                              daily: _daily,
                              onChanged: (v) => setState(() => _daily = v)),
                          const SizedBox(height: 12),
                          _TotalsHeader(
                              totals: w.totals, daily: _daily, marked: w.marked),
                          for (final worker in w.workers)
                            _WorkerCard(worker: worker, daily: _daily),
                          const SizedBox(height: 14),
                          _NoticeCard(notes: w.notes, hometaxNote: w.hometaxNote),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _copy(w),
                                  icon: Icon(Icons.copy_rounded,
                                      size: 18, color: c.ink),
                                  label: Text(l.wageStmtCopy,
                                      style: TextStyle(
                                          color: c.ink,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    side: BorderSide(color: c.borderStrong),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: (_marking || w.marked)
                                      ? null
                                      : () => _mark(month),
                                  icon: Icon(
                                      w.marked
                                          ? Icons.lock_rounded
                                          : Icons.check_circle_outline_rounded,
                                      size: 18),
                                  label: Text(
                                      w.marked ? l.wageStmtMarked : l.wageStmtMark,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    backgroundColor: c.primary,
                                    foregroundColor: c.primaryInk,
                                    disabledBackgroundColor:
                                        c.deposited.withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, WageStatement w) {
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          PaperCard(
            stamp: l.wageStmtTitle,
            child: Text(l.wageStmtEmpty,
                style: TextStyle(fontSize: 15, color: context.c.ink2)),
          ),
          const SizedBox(height: 16),
          _NoticeCard(notes: w.notes, hometaxNote: w.hometaxNote),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthSelector(
      {required this.month, required this.onPrev, required this.onNext});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded)),
        Text(fmtMonth(month, context.lang),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
        IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded)),
      ],
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final bool daily;
  final ValueChanged<bool> onChanged;
  const _TypeToggle({required this.daily, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    Widget seg(String label, bool selected, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: selected ? Border.all(color: c.border) : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: const Color(0x141A2233),
                            blurRadius: 3,
                            offset: const Offset(0, 1))
                      ]
                    : null,
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? c.ink : c.ink3)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          seg(l.wageStmtType33, !daily, () => onChanged(false)),
          const SizedBox(width: 4),
          seg(l.wageStmtTypeDaily, daily, () => onChanged(true)),
        ],
      ),
    );
  }
}

class _TotalsHeader extends StatelessWidget {
  final WageTotals totals;
  final bool daily;
  final bool marked;
  const _TotalsHeader(
      {required this.totals, required this.daily, required this.marked});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    final tax = daily ? totals.dailyWage : totals.business33;
    return Container(
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.07),
        border: Border.all(color: c.primary.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.wageStmtTotalHeader,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: c.accentText)),
              const Spacer(),
              if (marked) _MarkedBadge(),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(totals.paidTotal, lang),
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          const SizedBox(height: 3),
          Text(l.wageStmtPaymentCount(totals.paymentCount),
              style: TextStyle(fontSize: 12.5, color: c.ink3)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                _kv(context, l.wageStmtTotalTax,
                    formatMoney(tax.totalTax, lang), c.receivable),
                const SizedBox(height: 6),
                _kv(context, l.wageStmtNetPay, formatMoney(tax.netPay, lang),
                    c.ink,
                    bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String label, String value, Color color,
      {bool bold = false}) {
    final c = context.c;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13.5, color: c.ink2)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

class _MarkedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.deposited.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 12, color: c.depositedBadge),
          const SizedBox(width: 3),
          Text(l.wageStmtMarked,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: c.depositedBadge)),
        ],
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WageWorker worker;
  final bool daily;
  const _WorkerCard({required this.worker, required this.daily});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    final tax = daily ? worker.dailyWage : worker.business33;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyAvatar(name: worker.workerName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.workerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.ink)),
                    Text(
                        '${l.siteCostsManDays(formatGongsu(worker.workDays))} · ${l.wageStmtPaymentCount(worker.paymentCount)}',
                        style: TextStyle(fontSize: 13, color: c.ink2)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatMoney(worker.paidTotal, lang),
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  Text(l.wageStmtPaidTotal,
                      style: TextStyle(fontSize: 11.5, color: c.ink3)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                _taxRow(context, l.wageStmtIncomeTax,
                    formatMoney(tax.incomeTax, lang)),
                const SizedBox(height: 6),
                _taxRow(context, l.wageStmtLocalTax,
                    formatMoney(tax.localTax, lang)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: c.border),
                ),
                _taxRow(context, l.wageStmtTotalTax,
                    formatMoney(tax.totalTax, lang),
                    color: c.receivable, bold: true),
                const SizedBox(height: 6),
                _taxRow(context, l.wageStmtNetPay,
                    formatMoney(tax.netPay, lang),
                    color: c.deposited, bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taxRow(BuildContext context, String label, String value,
      {Color? color, bool bold = false}) {
    final c = context.c;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? c.ink : c.ink2)),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color ?? c.ink,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

/// 안내 노트 — 서버 제공 notes(세무사 확인 권장 등) + 홈택스 직접 입력 안내(주민번호 비수집).
class _NoticeCard extends StatelessWidget {
  final List<String> notes;
  final String hometaxNote;
  const _NoticeCard({required this.notes, required this.hometaxNote});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lines = [
      ...notes,
      if (hometaxNote.isNotEmpty) hometaxNote,
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.warnBg,
        border: Border.all(color: c.warnBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 17, color: c.warnInk),
              const SizedBox(width: 6),
              Text(l.wageStmtNoticeTitle,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.warnInk)),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('· ',
                      style: TextStyle(fontSize: 13.5, color: c.warnInk)),
                  Expanded(
                    child: Text(line,
                        style: TextStyle(
                            fontSize: 13.5, height: 1.4, color: c.warnInk)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
