import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/partners.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'partner_detail_screen.dart';

/// 거래처 목록 — 확인서 상대(수기 + 연결)가 자동으로 모이는 화면.
class PartnersScreen extends ConsumerStatefulWidget {
  const PartnersScreen({super.key});
  @override
  ConsumerState<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends ConsumerState<PartnersScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// 이름/전화 부분일치 필터(클라이언트).
  List<Partner> _filter(List<Partner> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) {
      final name = p.name.toLowerCase();
      final alias = (p.alias ?? '').toLowerCase();
      final phone = (p.phone ?? '').toLowerCase();
      return name.contains(q) || alias.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final async = ref.watch(partnersProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.partnersTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: TextField(
                controller: _search,
                style: TextStyle(fontSize: 16, color: c.ink),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l.partnersSearchHint,
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: c.ink3),
                  filled: true,
                  fillColor: c.fieldBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.border)),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(partnersProvider),
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => ListView(
                    padding: const EdgeInsets.fromLTRB(18, 40, 18, 18),
                    children: [
                      ErrorRetry(
                        boxed: false,
                        onRetry: () => ref.invalidate(partnersProvider),
                      ),
                    ],
                  ),
                  data: (all) {
                    final items = _filter(all);
                    if (items.isEmpty) {
                      return ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                            child: Column(
                              children: [
                                Icon(Icons.contacts_outlined,
                                    size: 48, color: c.ink3),
                                const SizedBox(height: 14),
                                Text(
                                  all.isEmpty
                                      ? l.partnersEmpty
                                      : l.partnersSearchHint,
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(fontSize: 15, color: c.ink2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _PartnerCard(partner: items[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 거래처 카드 1건.
class _PartnerCard extends StatelessWidget {
  final Partner partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    final p = partner;
    final settled = p.outstanding <= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PartnerDetailScreen(partner: p))),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: c.ink)),
                          ),
                          if (p.linked) ...[
                            const SizedBox(width: 6),
                            _LinkedBadge(),
                          ],
                        ],
                      ),
                    ),
                    // 미수 잔액 강조 / 정산 완료.
                    if (settled)
                      Text(l.partnerSettledLabel,
                          style: TextStyle(fontSize: 13, color: c.ink3))
                    else
                      Text(formatMoney(p.outstanding, lang),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.receivable,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                  ],
                ),
                if ((p.alias ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(p.alias!,
                        style: TextStyle(fontSize: 13, color: c.ink3)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.description_outlined, size: 14, color: c.ink3),
                    const SizedBox(width: 4),
                    Text(l.partnerConfCount(p.confirmationCount),
                        style: TextStyle(
                            fontSize: 12.5,
                            color: c.ink2,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ])),
                    if (p.lastWorkedDate != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.event_outlined, size: 14, color: c.ink3),
                      const SizedBox(width: 4),
                      Text(_fmtDate(p.lastWorkedDate!, lang),
                          style: TextStyle(fontSize: 12.5, color: c.ink2)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(String ymd, String lang) {
    final d = DateTime.tryParse(ymd);
    return d == null ? ymd : fmtShortDate(d, lang);
  }
}

/// "연결" 배지 칩.
class _LinkedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(context.l.partnerLinkedBadge,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.accentText)),
    );
  }
}
