import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/biz.dart';
import '../../widgets/common.dart';

/// 기간 프리셋 — 이번 달 기본, 최대 12개월.
enum _RangePreset { thisMonth, m3, m6, m12 }

({String from, String to}) _resolveRange(_RangePreset p) {
  final now = DateTime.now();
  final to = '${now.year}-${_two(now.month)}';
  switch (p) {
    case _RangePreset.thisMonth:
      return (from: to, to: to);
    case _RangePreset.m3:
      final s = DateTime(now.year, now.month - 2);
      return (from: '${s.year}-${_two(s.month)}', to: to);
    case _RangePreset.m6:
      final s = DateTime(now.year, now.month - 5);
      return (from: '${s.year}-${_two(s.month)}', to: to);
    case _RangePreset.m12:
      final s = DateTime(now.year, now.month - 11);
      return (from: '${s.year}-${_two(s.month)}', to: to);
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 사업장 메뉴 "현장별 인건비" — 기간 선택 → 현장 카드(소계·인원) → 펼치면
/// 작업자별 내역(팀 배지·인원수) → 총계 헤더 → PDF 저장·공유(인증 blob).
class SiteCostsScreen extends ConsumerStatefulWidget {
  const SiteCostsScreen({super.key});
  @override
  ConsumerState<SiteCostsScreen> createState() => _SiteCostsScreenState();
}

class _SiteCostsScreenState extends ConsumerState<SiteCostsScreen> {
  _RangePreset _preset = _RangePreset.thisMonth;
  bool _sharing = false;

  Future<void> _share(({String from, String to}) range) async {
    setState(() => _sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    final box = context.findRenderObject() as RenderBox?;
    try {
      final bytes = await ref
          .read(bizRepoProvider)
          .siteCostsPdf(from: range.from, to: range.to);
      final dir = await getTemporaryDirectory();
      final file =
          File('${dir.path}/site-costs-${range.from}_${range.to}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: '${l.siteCostsTitle} ${range.from}~${range.to}',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(l.siteCostsPdfFail('$e'))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final range = _resolveRange(_preset);
    final costs = ref.watch(siteCostsProvider(range));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.siteCostsTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          color: c.primary,
          onRefresh: () async {
            ref.invalidate(siteCostsProvider(range));
            try {
              await ref.read(siteCostsProvider(range).future);
            } catch (_) {}
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _PresetSelector(
                preset: _preset,
                onChanged: (p) => setState(() => _preset = p),
              ),
              const SizedBox(height: 6),
              Text(l.siteCostsRangeLabel(range.from, range.to),
                  style: TextStyle(
                      fontSize: 13,
                      color: c.ink3,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(height: 12),
              costs.when(
                loading: () => const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: ErrorRetry(
                        onRetry: () =>
                            ref.invalidate(siteCostsProvider(range)))),
                data: (d) => d.sites.isEmpty
                    ? _empty(context)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TotalsHeader(totals: d.totals),
                          const SizedBox(height: 4),
                          for (final site in d.sites)
                            _SiteCard(site: site),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: l.siteCostsSavePdf,
                            icon: Icons.ios_share_rounded,
                            loading: _sharing,
                            onPressed: () => _share(range),
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
        stamp: l.siteCostsTitle,
        child: Text(l.siteCostsEmpty,
            style: TextStyle(fontSize: 15, color: context.c.ink2)),
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  final _RangePreset preset;
  final ValueChanged<_RangePreset> onChanged;
  const _PresetSelector({required this.preset, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final items = <_RangePreset, String>{
      _RangePreset.thisMonth: l.siteCostsThisMonth,
      _RangePreset.m3: l.siteCostsLast3,
      _RangePreset.m6: l.siteCostsLast6,
      _RangePreset.m12: l.siteCostsLast12,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in items.entries)
          _Chip(
              label: e.value,
              selected: e.key == preset,
              onTap: () => onChanged(e.key)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: selected ? c.primary.withValues(alpha: 0.14) : c.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: selected ? c.primary : c.border,
                width: selected ? 1.4 : 1),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? c.accentText : c.ink2)),
        ),
      ),
    );
  }
}

class _TotalsHeader extends StatelessWidget {
  final SiteCostTotals totals;
  const _TotalsHeader({required this.totals});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
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
          Text(l.siteCostsTotalHeader,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: c.accentText)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(totals.totalAmount, lang),
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          const SizedBox(height: 6),
          Text(
              '${l.siteCostsManDays(formatGongsu(totals.totalDays))}'
              '${totals.totalGongsu > 0 ? ' · ${l.qtyGongsu(formatGongsu(totals.totalGongsu))}' : ''}'
              ' · ${l.siteCostsEntryCount(totals.entryCount)}',
              style: TextStyle(fontSize: 13, color: c.ink2)),
        ],
      ),
    );
  }
}

class _SiteCard extends StatefulWidget {
  final SiteCostSite site;
  const _SiteCard({required this.site});
  @override
  State<_SiteCard> createState() => _SiteCardState();
}

class _SiteCardState extends State<_SiteCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    final s = widget.site;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, size: 19, color: c.accentText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.site,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: c.ink)),
                        const SizedBox(height: 2),
                        Text(
                            '${l.siteCostsWorkerCount(s.workerCount)} · ${l.siteCostsManDays(formatGongsu(s.subtotalDays))}',
                            style:
                                TextStyle(fontSize: 13, color: c.ink2)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatMoney(s.subtotalAmount, lang),
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.ink,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                      Text(l.siteCostsSubtotal,
                          style: TextStyle(fontSize: 11.5, color: c.ink3)),
                    ],
                  ),
                  Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: c.ink3),
                ],
              ),
            ),
          ),
          if (_expanded)
            Column(
              children: [
                Divider(height: 1, color: c.border),
                for (final e in s.entries) _EntryRow(entry: e),
              ],
            ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final SiteCostEntry entry;
  const _EntryRow({required this.entry});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(entry.workerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.ink)),
                    ),
                    if (entry.isTeam) ...[
                      const SizedBox(width: 6),
                      const TeamBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                    [
                      if (entry.isTeam)
                        l.siteCostsTeamMembers(entry.teamMemberCount),
                      l.siteCostsManDays(formatGongsu(entry.days)),
                      if (entry.gongsu > 0)
                        l.qtyGongsu(formatGongsu(entry.gongsu)),
                    ].join(' · '),
                    style: TextStyle(fontSize: 12.5, color: c.ink2)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(formatMoney(entry.amount, lang),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
