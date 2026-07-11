import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import 'income_report_pdf.dart';

/// 더보기 → 소득 리포트: 연도 선택 → 총계 카드 + 월별 추이(커스텀 막대) +
/// 상대별 리스트 + 종소세 안내 + PDF 저장·공유.
class IncomeReportScreen extends ConsumerStatefulWidget {
  const IncomeReportScreen({super.key});
  @override
  ConsumerState<IncomeReportScreen> createState() =>
      _IncomeReportScreenState();
}

class _IncomeReportScreenState extends ConsumerState<IncomeReportScreen> {
  late int _year = DateTime.now().year;
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final report = ref.watch(incomeReportProvider(_year));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.incomeReportTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          color: c.primary,
          onRefresh: () async {
            ref.invalidate(incomeReportProvider);
            try {
              await ref.read(incomeReportProvider(_year).future);
            } catch (_) {}
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _YearSelector(
                year: _year,
                onPrev: () => setState(() => _year -= 1),
                onNext: _year >= DateTime.now().year
                    ? null
                    : () => setState(() => _year += 1),
              ),
              const SizedBox(height: 14),
              report.when(
                loading: () => const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                        child: ErrorRetry(
                            boxed: false,
                            onRetry: () =>
                                ref.invalidate(incomeReportProvider)))),
                data: (r) => r.entryCount == 0
                    ? _empty(context)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TotalsCard(report: r),
                          SectionTitle(l.incomeReportMonthlyTrend),
                          _MonthlyTrendCard(monthly: r.monthly),
                          SectionTitle(l.incomeReportByCompany,
                              trailing: Text(
                                  l.ledgerCompanyCount(r.companies.length),
                                  style:
                                      TextStyle(fontSize: 13, color: c.ink3))),
                          _CompanyListCard(companies: r.companies),
                          SectionTitle(l.incomeReportTaxTitle),
                          const _TaxNoticeCard(),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: l.incomeReportSavePdf,
                            icon: Icons.ios_share_rounded,
                            loading: _sharing,
                            onPressed: () => _share(context),
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

  Widget _empty(BuildContext context) {
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: PaperCard(
        stamp: l.incomeReportTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.incomeReportEmptyTitle,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.c.ink)),
            const SizedBox(height: 4),
            Text(l.incomeReportEmptySub,
                style: TextStyle(fontSize: 14, color: context.c.ink2)),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    try {
      await shareIncomeReport(ref, _year, context: context);
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(l.incomeReportPdfFail('$e'))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _YearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  const _YearSelector(
      {required this.year, required this.onPrev, required this.onNext});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navBtn(context, Icons.chevron_left_rounded, onPrev),
          Text(context.l.incomeReportYear('$year'),
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800, color: c.ink)),
          _navBtn(context, Icons.chevron_right_rounded, onNext),
        ],
      ),
    );
  }

  Widget _navBtn(BuildContext context, IconData icon, VoidCallback? onTap) =>
      InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
            width: 48,
            height: 44,
            child: Icon(icon,
                color: onTap == null ? context.c.ink3.withValues(alpha: 0.3)
                    : context.c.ink2)),
      );
}

class _TotalsCard extends StatelessWidget {
  final IncomeReport report;
  const _TotalsCard({required this.report});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.incomeReportTotalBilled,
              style: TextStyle(fontSize: 13.5, color: c.ink2)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(report.totalBilled, lang),
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat(context, l.incomeReportTotalPaid,
                  formatMoney(report.totalPaid, lang), c.deposited),
              _divider(c),
              _stat(context, l.incomeReportTotalOutstanding,
                  formatMoney(report.totalOutstanding, lang), c.receivable),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(context, l.incomeReportTotalDays,
                  l.daysCount(report.totalDays), c.ink),
              _divider(c),
              _stat(
                  context,
                  l.incomeReportTotalGongsu,
                  report.totalGongsu > 0
                      ? l.qtyGongsu(formatGongsu(report.totalGongsu))
                      : '-',
                  c.ink),
            ],
          ),
          if (report.teamPayout > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv(context, l.incomeReportTeamPayout,
                      formatMoney(report.teamPayout, lang), c.ink2),
                  const SizedBox(height: 6),
                  _kv(context, l.incomeReportNetBilled,
                      formatMoney(report.netBilled, lang), c.ink,
                      bold: true),
                  const SizedBox(height: 4),
                  Text(l.incomeReportNetHint,
                      style: TextStyle(fontSize: 11.5, color: c.ink3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, Color color) {
    final c = context.c;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: c.ink3)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()])),
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
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }

  Widget _divider(AppColors c) => Container(
      width: 1, height: 34, color: c.border, margin: const EdgeInsets.symmetric(horizontal: 12));
}

/// 월별 청구액 막대(커스텀 페인트 — 차트 라이브러리 미사용).
class _MonthlyTrendCard extends StatelessWidget {
  final List<IncomeMonthly> monthly;
  const _MonthlyTrendCard({required this.monthly});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lang = context.lang;
    final maxBilled = monthly.fold<int>(0, (m, e) => e.billed > m ? e.billed : m);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              maxBilled > 0
                  ? context.l.incomeReportPeakLabel(formatMoney(maxBilled, lang))
                  : '-',
              style: TextStyle(fontSize: 12.5, color: c.ink3)),
          const SizedBox(height: 10),
          SizedBox(
            height: 132,
            child: CustomPaint(
              size: const Size(double.infinity, 132),
              painter: _BarsPainter(
                monthly: monthly,
                maxBilled: maxBilled,
                barColor: c.primary,
                emptyColor: c.border,
                labelColor: c.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<IncomeMonthly> monthly;
  final int maxBilled;
  final Color barColor;
  final Color emptyColor;
  final Color labelColor;
  _BarsPainter({
    required this.monthly,
    required this.maxBilled,
    required this.barColor,
    required this.emptyColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (monthly.isEmpty) return;
    const labelH = 16.0;
    final chartH = size.height - labelH;
    final n = monthly.length;
    final slot = size.width / n;
    final barW = slot * 0.56;
    final barPaint = Paint()..color = barColor;
    final basePaint = Paint()..color = emptyColor;

    for (var i = 0; i < n; i++) {
      final m = monthly[i];
      final cx = slot * i + slot / 2;
      final ratio = maxBilled > 0 ? m.billed / maxBilled : 0.0;
      final h = (chartH - 4) * ratio;
      final left = cx - barW / 2;
      // baseline tick (빈 달도 얇게 표시)
      final baseY = chartH;
      if (m.billed <= 0) {
        final r = RRect.fromLTRBR(
            left, baseY - 3, left + barW, baseY, const Radius.circular(2));
        canvas.drawRRect(r, basePaint);
      } else {
        final top = baseY - (h < 3 ? 3 : h);
        final r = RRect.fromLTRBR(
            left, top, left + barW, baseY, const Radius.circular(3));
        canvas.drawRRect(r, barPaint);
      }
      // 월 라벨 (1,4,7,10 만 표시해 혼잡 방지)
      final monthNum = int.tryParse(
              m.month.contains('-') ? m.month.split('-')[1] : m.month) ??
          (i + 1);
      if (monthNum % 3 == 1) {
        final tp = TextPainter(
          text: TextSpan(
              text: '$monthNum',
              style: TextStyle(fontSize: 10, color: labelColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, chartH + 3));
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.monthly != monthly || old.maxBilled != maxBilled;
}

class _CompanyListCard extends StatelessWidget {
  final List<IncomeCompany> companies;
  const _CompanyListCard({required this.companies});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < companies.length; i++)
            _row(context, companies[i], i == companies.length - 1),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IncomeCompany co, bool last) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    return Container(
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CompanyAvatar(name: co.companyName, paid: co.outstanding == 0),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(co.companyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.ink)),
                const SizedBox(height: 2),
                Text(
                    l.incomeReportEntryCount(co.count) +
                        (co.outstanding > 0
                            ? ' · ${l.incomeReportOutstandingShort(formatMoney(co.outstanding, lang))}'
                            : ''),
                    style: TextStyle(fontSize: 13, color: c.ink2)),
              ],
            ),
          ),
          Text(formatMoney(co.total, lang),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class _TaxNoticeCard extends StatelessWidget {
  const _TaxNoticeCard();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lines = [
      l.incomeReportTaxL1,
      l.incomeReportTaxL2,
      l.incomeReportTaxL3,
      l.incomeReportTaxL4,
      l.incomeReportTaxL5,
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
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
