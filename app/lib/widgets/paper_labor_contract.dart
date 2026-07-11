import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../core/format.dart';
import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import 'common.dart';

/// 종이 표준근로계약서 렌더 — 조항 라벨은 번역(context.l.lc*), 계약 데이터 값은 원문 유지.
/// 하단에 정본(한국어본) 안내 문구를 반드시 표기한다(웹 PaperLaborContract 미러).
class PaperLaborContract extends StatelessWidget {
  final LaborContract c;
  const PaperLaborContract({super.key, required this.c});

  String _fmtDate(BuildContext context, String ymd) {
    final d = DateTime.tryParse(ymd);
    return d == null ? ymd : fmtShortDate(d, context.lang);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.c;
    final l = context.l;
    final lang = context.lang;
    final wageLabel = c.wageType == 'HOURLY' ? l.lcWageHourly : l.lcWageDaily;
    final periodValue = c.endDate != null && c.endDate!.isNotEmpty
        ? '${_fmtDate(context, c.startDate)} ~ ${_fmtDate(context, c.endDate!)}'
        : '${_fmtDate(context, c.startDate)} · ${l.lcPeriodOpen}';
    final workTimeValue = (c.breakTime != null && c.breakTime!.isNotEmpty)
        ? '${c.workStartTime} ~ ${c.workEndTime} · ${l.lcBreak} ${c.breakTime}'
        : '${c.workStartTime} ~ ${c.workEndTime}';

    return PaperCard(
      stamp: l.lcStamp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 계약 당사자
          _sectionHead(context, l.lcParties),
          _line(context, l.lcEmployer, c.businessName ?? ''),
          _line(context, l.lcWorkerParty, c.workerName),
          const SizedBox(height: 8),
          Divider(height: 1, color: col.border),
          const SizedBox(height: 10),
          // 계약 내용
          _line(context, l.lcPeriod, periodValue),
          _line(context, l.lcWorkplace, c.workplace),
          _line(context, l.lcJob, c.jobDescription),
          _line(context, l.lcWorkTime, workTimeValue),
          _line(context, l.lcWage,
              '${formatMoney(c.wageAmount, lang)} · $wageLabel'),
          _line(context, l.lcPayday, c.payday),
          _line(context, l.lcPayMethod, c.payMethod),
          const SizedBox(height: 12),
          // 수당
          _sectionHead(context, l.lcAllowance),
          Text(
              c.weeklyHolidayAllowance
                  ? l.lcWeeklyHoliday
                  : l.lcWeeklyHolidayNone,
              style: TextStyle(fontSize: 13.5, color: col.ink2, height: 1.45)),
          const SizedBox(height: 4),
          Text(c.overtimeAllowance ? l.lcOvertime : l.lcOvertimeNone,
              style: TextStyle(fontSize: 13.5, color: col.ink2, height: 1.45)),
          const SizedBox(height: 12),
          // 사회보험
          _sectionHead(context, l.lcInsurance),
          _insRow(context, l.lcInsEmployment, c.insEmployment()),
          _insRow(context, l.lcInsHealth, c.insHealth()),
          _insRow(context, l.lcInsPension, c.insPension()),
          _insRow(context, l.lcInsAccident, c.insAccident()),
          // 특약사항
          if (c.specialTerms != null && c.specialTerms!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('${l.lcSpecial} · ${c.specialTerms}',
                style: TextStyle(fontSize: 14, color: col.ink2, height: 1.45)),
          ],
          // 정본(한국어본) 안내
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: col.border)),
            ),
            child: Text('※ ${l.lcMasterNote}',
                style: TextStyle(fontSize: 12.5, color: col.ink3, height: 1.55)),
          ),
          // 서명 상태
          if (c.employerSigned) ...[
            const SizedBox(height: 14),
            _signBadge(
                context,
                l.lcEmployer,
                c.employerSignerName != null
                    ? l.paperSignedBy(c.employerSignerName!)
                    : l.lcEmployerSigned,
                c.employerSignedAt),
          ],
          if (c.workerSigned) ...[
            const SizedBox(height: 10),
            _signBadge(context, l.lcWorkerParty,
                l.paperSignedBy(c.workerSignerName ?? ''), c.workerSignedAt),
          ],
        ],
      ),
    );
  }

  Widget _sectionHead(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: context.c.accentText,
                letterSpacing: 0.3)),
      );

  Widget _line(BuildContext context, String label, String value) {
    final col = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 92,
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: col.ink2))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: col.ink,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _insRow(BuildContext context, String label, bool applied) {
    final col = context.c;
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(applied ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
              size: 16, color: applied ? col.depositedBadge : col.ink3),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, color: col.ink2)),
          const Spacer(),
          Text(applied ? l.lcApplied : l.lcNotApplied,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: applied ? col.depositedBadge : col.ink3)),
        ],
      ),
    );
  }

  Widget _signBadge(
      BuildContext context, String role, String text, String? at) {
    final col = context.c;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: col.deposited.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: col.depositedBadge, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$role · $text',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: col.depositedBadge)),
                if (at != null && at.isNotEmpty)
                  Text(at,
                      style: TextStyle(
                          fontSize: 12,
                          color: col.ink3,
                          fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
