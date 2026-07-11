import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../core/api_client.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';

class CompanyDetailScreen extends ConsumerWidget {
  final String month;
  final LedgerCompany company;
  const CompanyDetailScreen({super.key, required this.month, required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final entries = ref.watch(ledgerEntriesProvider(month));
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(company.companyName)),
      body: entries.when(
        loading: () => Center(child: CircularProgressIndicator(color: c.primary)),
        error: (e, _) => Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorRetry(
                    boxed: false,
                    onRetry: () => ref.invalidate(ledgerEntriesProvider)))),
        data: (all) {
          final items = all
              .where((e) => company.businessId != null
                  ? e.businessId == company.businessId
                  : e.businessId == null && e.companyName == company.companyName)
              .toList();
          final outstanding =
              items.fold<int>(0, (s, e) => s + e.outstanding);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // 합계 헤더
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CompanyAvatar(
                        name: company.companyName, paid: company.status == 'PAID'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.ledgerRemaining,
                              style: TextStyle(fontSize: 13, color: c.ink2)),
                          Text(formatMoney(outstanding, context.lang),
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: outstanding == 0 ? c.deposited : c.receivable,
                                  fontFeatures: const [FontFeature.tabularFigures()])),
                        ],
                      ),
                    ),
                    DdayBadge(
                        dday: company.dday,
                        status: company.status,
                        label: ddayText(l, company.dday, company.status)),
                  ],
                ),
              ),
              SectionTitle(l.ledgerWorkHistory),
              for (final e in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _EntryTile(entry: e),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  final LedgerEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    final paid = entry.status == 'PAID';
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: paid ? null : () => _openPaymentSheet(context, ref, entry),
        child: Container(
          padding: const EdgeInsets.all(14),
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
                    Text(
                        '${entry.date != null ? fmtShortDate(DateTime.parse(entry.date!), context.lang) : ''}'
                        '${entry.siteName != null ? ' · ${entry.siteName}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                    if (entry.derived) ...[
                      const SizedBox(height: 3),
                      Text(l.ledgerTeamDerived(entry.companyName),
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: c.accentText)),
                    ],
                    const SizedBox(height: 4),
                    Row(children: [
                      Text(l.ledgerBilled(formatMoney(entry.amount, context.lang)),
                          style: TextStyle(
                              fontSize: 13,
                              color: c.ink2,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                      if (entry.paid > 0) ...[
                        Text('  ·  ', style: TextStyle(color: c.ink3)),
                        Text(l.ledgerDeposited(formatMoney(entry.paid, context.lang)),
                            style: TextStyle(
                                fontSize: 13,
                                color: c.deposited,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ],
                    ]),
                    if (entry.derived)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(l.ledgerDerivedReadonly,
                            style: TextStyle(fontSize: 12, color: c.ink3)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatMoney(paid ? entry.amount : entry.outstanding, context.lang),
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: paid ? c.deposited : c.receivable,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  const SizedBox(height: 4),
                  Text(entry.statusLabel,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: paid ? c.deposited : c.ink3)),
                ],
              ),
              if (!paid) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: c.ink3),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _openPaymentSheet(BuildContext context, WidgetRef ref, LedgerEntry entry) {
  final amountCtl = TextEditingController(text: '${entry.outstanding}');
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.bg,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      // 시트 임시 컨트롤러 — 시트가 닫힐 때(whenComplete) 해제.
      final c = ctx.c;
      bool saving = false;
      return StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> save() async {
          final amount = int.tryParse(amountCtl.text.trim()) ?? 0;
          if (amount <= 0) return;
          setSheet(() => saving = true);
          try {
            await ref.read(repoProvider).addPayment(entry.id, amount);
            invalidateAll(ref);
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l.ledgerPaymentSaved)));
            }
          } on ApiException catch (e) {
            setSheet(() => saving = false);
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(ctx.l.ledgerPaymentFail(e.message))));
            }
          }
        }

        return Padding(
          padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 14,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 18),
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
              const SizedBox(height: 16),
              Text(ctx.l.ledgerRecordPayment,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: 4),
              Text(
                  '${entry.companyName} · ${ctx.l.ledgerRemainingAmount(formatMoney(entry.outstanding, ctx.lang))}',
                  style: TextStyle(fontSize: 14, color: c.ink2)),
              const SizedBox(height: 16),
              Text(ctx.l.ledgerPaymentAmount,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: c.ink2)),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()]),
                decoration: InputDecoration(suffixText: ctx.l.ledgerWonSuffix),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _quick(ctx, amountCtl, ctx.l.ledgerFull, entry.outstanding),
                const SizedBox(width: 8),
                _quick(ctx, amountCtl, ctx.l.ledgerHalf, (entry.outstanding / 2).round()),
              ]),
              const SizedBox(height: 18),
              PrimaryButton(
                label: ctx.l.ledgerRecordPaymentBtn,
                icon: Icons.check_rounded,
                loading: saving,
                onPressed: save,
              ),
            ],
          ),
        );
      });
    },
  ).whenComplete(amountCtl.dispose);
}

Widget _quick(BuildContext context, TextEditingController ctl, String label, int value) {
  final c = context.c;
  return GestureDetector(
    onTap: () => ctl.text = '$value',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label ${formatMoney(value, context.lang)}',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: c.accentText)),
    ),
  );
}
