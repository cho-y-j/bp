import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../core/api_client.dart';
import '../../models/models.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../../l10n/l10n_ext.dart';
import 'business_info_screen.dart';
import 'tax_invoice_text.dart';

/// 세금계산서 준비 화면 — 월 선택 → 상대별 카드 → 복사 → 발행 완료 표시.
class TaxInvoiceScreen extends ConsumerStatefulWidget {
  const TaxInvoiceScreen({super.key});
  @override
  ConsumerState<TaxInvoiceScreen> createState() => _TaxInvoiceScreenState();
}

class _TaxInvoiceScreenState extends ConsumerState<TaxInvoiceScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final mp = monthParam(_month);
    final data = ref.watch(taxInvoiceDataProvider(mp));
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.taxTitle)),
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () async {
          ref.invalidate(taxInvoiceDataProvider);
          try {
            await ref.read(taxInvoiceDataProvider(mp).future);
          } catch (_) {}
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 월 네비
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  _nav(Icons.chevron_left_rounded,
                      () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
                  Expanded(
                    child: Center(
                      child: Text(fmtMonth(_month, context.lang),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: c.ink)),
                    ),
                  ),
                  _nav(Icons.chevron_right_rounded,
                      () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            data.when(
              loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: ErrorRetry(
                      onRetry: () => ref.invalidate(taxInvoiceDataProvider))),
              data: (d) => _Content(month: mp, data: d),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nav(IconData icon, VoidCallback onTap) => InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox(
            width: 44, height: 44, child: Icon(icon, color: context.c.ink3)),
      );
}

class _Content extends ConsumerWidget {
  final String month;
  final TaxInvoiceData data;
  const _Content({required this.month, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final l = context.l;
    if (!data.supplierReady) {
      return _SupplierPrompt();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 공급자 요약
        Container(
          decoration: BoxDecoration(
            color: c.surface2,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.badge_outlined, size: 20, color: c.accentText),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        l.taxSupplierPrefix(
                            data.supplier.bizName ?? l.taxNoBizName),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: c.ink)),
                    Text(l.taxBizNumberLine(data.supplier.bizNumber ?? '-'),
                        style: TextStyle(fontSize: 13, color: c.ink2)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BusinessInfoScreen())),
                child: Text(l.edit,
                    style: TextStyle(
                        color: c.accentText, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 홈택스 안내
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.07),
            border: Border.all(color: c.borderStrong),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: c.accentText),
              const SizedBox(width: 9),
              Expanded(
                child: Text(l.taxHometaxGuide,
                    style: TextStyle(fontSize: 12.5, color: c.ink2, height: 1.35)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (data.groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 44, color: c.ink3),
                const SizedBox(height: 12),
                Text(l.taxEmptyTitle,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                const SizedBox(height: 4),
                Text(l.taxEmptySubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: c.ink2)),
              ],
            ),
          )
        else
          for (final g in data.groups)
            _GroupCard(month: month, supplier: data.supplier, group: g),
      ],
    );
  }
}

class _SupplierPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Column(
      children: [
        PaperCard(
          stamp: l.taxStamp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.taxSupplierPromptTitle,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
              const SizedBox(height: 4),
              Text(l.taxSupplierPromptDesc,
                  style: TextStyle(fontSize: 14, color: c.ink2)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: l.taxEnterBizInfo,
          icon: Icons.badge_outlined,
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessInfoScreen())),
        ),
      ],
    );
  }
}

class _GroupCard extends ConsumerStatefulWidget {
  final String month;
  final TaxInvoiceSupplier supplier;
  final TaxInvoiceGroup group;
  const _GroupCard(
      {required this.month, required this.supplier, required this.group});
  @override
  ConsumerState<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends ConsumerState<_GroupCard> {
  bool _marking = false;

  Future<void> _copy() async {
    final text = taxInvoiceCopyText(widget.supplier, widget.group);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.taxCopiedSnack)));
  }

  Future<void> _mark() async {
    setState(() => _marking = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    try {
      final res =
          await ref.read(repoProvider).markTaxInvoiced(widget.group.ledgerIds);
      ref.invalidate(taxInvoiceDataProvider);
      if (!mounted) return;
      final marked = (res['marked'] as num?)?.toInt() ?? 0;
      messenger.showSnackBar(SnackBar(
          content: Text(marked > 0
              ? l.taxMarkedSnack
              : l.taxAlreadyMarkedSnack)));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _marking = false);
        messenger.showSnackBar(
            SnackBar(content: Text(l.taxMarkFailed(e.message))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final g = widget.group;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(g.buyerName,
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: c.ink)),
              ),
              _RegBadge(registered: g.buyerRegistered),
            ],
          ),
          const SizedBox(height: 2),
          Text(
              l.taxBuyerBizLine(
                  g.buyerBizNumber ?? l.taxNotRegistered, g.items.length),
              style: TextStyle(fontSize: 13, color: c.ink2)),
          const SizedBox(height: 12),
          _amountRow(context, l.taxSupplyAmount, g.supplyTotal, bold: false),
          const SizedBox(height: 4),
          _amountRow(context, l.vatLabel('10'), g.taxTotal, bold: false),
          const SizedBox(height: 6),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 8),
          _amountRow(context, l.taxGrandTotal, g.grandTotal, bold: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copy,
                  icon: Icon(Icons.copy_outlined, size: 18, color: c.ink),
                  label: Text(l.taxCopy,
                      style: TextStyle(
                          color: c.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.borderStrong),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _marking ? null : _mark,
                  icon: _marking
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: c.primaryInk))
                      : Icon(Icons.check_rounded, size: 18, color: c.primaryInk),
                  label: Text(l.taxMarkIssued,
                      style: TextStyle(
                          color: c.primaryInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountRow(BuildContext context, String label, int amount,
      {required bool bold}) {
    final c = context.c;
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 15 : 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? c.ink : c.ink2)),
        const Spacer(),
        Text(formatMoney(amount, context.lang),
            style: TextStyle(
                fontSize: bold ? 18 : 14.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                color: c.ink,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

class _RegBadge extends StatelessWidget {
  final bool registered;
  const _RegBadge({required this.registered});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final bg = registered
        ? c.deposited.withValues(alpha: 0.12)
        : c.warnBg;
    final fg = registered ? c.depositedBadge : c.warnInk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: registered ? null : Border.all(color: c.warnBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(registered ? Icons.verified_outlined : Icons.help_outline_rounded,
              size: 13, color: fg),
          const SizedBox(width: 3),
          Text(registered ? l.taxRegisteredBadge : l.taxCheckNeeded,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}
