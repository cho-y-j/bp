import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../confirmation/confirmation_form_screen.dart';
import 'ledger_pdf.dart';
import 'company_detail_screen.dart';

class LedgerScreen extends ConsumerWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final month = ref.watch(selectedMonthProvider);
    final mp = monthParam(month);
    final summary = ref.watch(ledgerSummaryProvider(mp));
    final companies = ref.watch(ledgerByCompanyProvider(mp));

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.primary,
          onRefresh: () async {
            ref.invalidate(ledgerByCompanyProvider);
            ref.invalidate(ledgerSummaryProvider);
            ref.invalidate(ledgerEntriesProvider);
            // 새로고침 실패는 ErrorRetry 로 표시되므로 여기서는 삼킨다.
            try {
              await ref.read(ledgerByCompanyProvider(mp).future);
            } catch (_) {}
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
                child: Text('장부',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: c.ink)),
              ),
              // 월 헤더 + 미수 합계
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.fromLTRB(6, 8, 16, 8),
                child: Row(
                  children: [
                    _nav(context, Icons.chevron_left_rounded, () {
                      ref.read(selectedMonthProvider.notifier).state =
                          DateTime(month.year, month.month - 1);
                    }),
                    Text(formatMonthK(month),
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
                    _nav(context, Icons.chevron_right_rounded, () {
                      ref.read(selectedMonthProvider.notifier).state =
                          DateTime(month.year, month.month + 1);
                    }),
                    const Spacer(),
                    summary.when(
                      loading: () => const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (s) => Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('이번 달 미수 합계',
                              style: TextStyle(fontSize: 13, color: c.ink2)),
                          Text(formatWonUnit(s.totalOutstanding),
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: c.receivable,
                                  fontFeatures: const [FontFeature.tabularFigures()])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              companies.when(
                loading: () => const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                        child: ErrorRetry(
                            boxed: false,
                            onRetry: () {
                              ref.invalidate(ledgerByCompanyProvider);
                              ref.invalidate(ledgerSummaryProvider);
                              ref.invalidate(ledgerEntriesProvider);
                            }))),
                data: (list) {
                  if (list.isEmpty) {
                    return _LedgerEmpty();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle('회사별',
                          trailing: Text('${list.length}곳',
                              style: TextStyle(fontSize: 13, color: c.ink3))),
                      Container(
                        decoration: BoxDecoration(
                          color: c.surface,
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < list.length; i++)
                              _CompanyRow(
                                company: list[i],
                                last: i == list.length - 1,
                                month: mp,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StatementButton(month: mp),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nav(BuildContext context, IconData icon, VoidCallback onTap) => InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: context.c.ink3)),
      );
}

/// 장부 빈 상태 — 홈 빈 상태(PaperCard)와 통일 + 확인서 작성 CTA.
class _LedgerEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          PaperCard(
            stamp: '장부 · WORKON',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이 달의 장부 기록이 없어요',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
                const SizedBox(height: 4),
                Text('확인서를 작성하면 장부가 자동으로 채워져요.',
                    style: TextStyle(fontSize: 14, color: c.ink2)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '확인서 작성하기',
            icon: Icons.add_rounded,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ConfirmationFormScreen(),
              fullscreenDialog: true,
            )),
          ),
        ],
      ),
    );
  }
}

class _CompanyRow extends StatelessWidget {
  final LedgerCompany company;
  final bool last;
  final String month;
  const _CompanyRow(
      {required this.company, required this.last, required this.month});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final paid = company.status == 'PAID';
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              CompanyDetailScreen(month: month, company: company))),
      child: Container(
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            CompanyAvatar(name: company.companyName, paid: paid),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.companyName,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                  const SizedBox(height: 2),
                  Text(
                      '${company.days}일 작업'
                      '${company.paid > 0 && !paid ? ' · ${formatWon(company.paid)}원 입금' : ''}',
                      style: TextStyle(fontSize: 13.5, color: c.ink2)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatWon(paid ? company.total : company.outstanding),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: paid ? c.deposited : c.receivable,
                        fontFeatures: const [FontFeature.tabularFigures()])),
                const SizedBox(height: 5),
                DdayBadge(
                    dday: company.dday,
                    status: company.status,
                    label: ddayText(company.dday, company.status)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementButton extends ConsumerStatefulWidget {
  final String month;
  const _StatementButton({required this.month});
  @override
  ConsumerState<_StatementButton> createState() => _StatementButtonState();
}

class _StatementButtonState extends ConsumerState<_StatementButton> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await openMonthlyStatement(ref, widget.month);
                } catch (e) {
                  if (mounted) {
                    messenger
                        .showSnackBar(SnackBar(content: Text('명세서 열기 실패: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        icon: _loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.ink))
            : Icon(Icons.description_outlined, color: c.ink, size: 19),
        label: Text('월간 명세서 PDF',
            style: TextStyle(color: c.ink, fontSize: 16, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
