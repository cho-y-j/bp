import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import 'share_helper.dart';

final _confDetailProvider =
    FutureProvider.family<Confirmation, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/confirmations/$id');
  return Confirmation.fromJson(res as Map);
});

class ConfirmationDetailScreen extends ConsumerWidget {
  final String confirmationId;
  const ConfirmationDetailScreen({super.key, required this.confirmationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final detail = ref.watch(_confDetailProvider(confirmationId));
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(context.l.confDetailTitle)),
      body: detail.when(
        loading: () => Center(child: CircularProgressIndicator(color: c.primary)),
        error: (e, _) => Center(child: Text('$e', style: TextStyle(color: c.ink2))),
        data: (conf) => _Body(conf: conf),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final Confirmation conf;
  const _Body({required this.conf});
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    final l = context.l;
    try {
      final repo = ref.read(repoProvider);
      final res = await repo.send(widget.conf.id);
      final url = res['url']?.toString() ?? '';
      final linked = res['linked'] == true;
      if (!mounted) return;
      if (linked) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.confSentLinked)));
      } else {
        await shareConfirmationLink(context, widget.conf, url);
      }
      ref.invalidate(_confDetailProvider(widget.conf.id));
      invalidateAll(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.confSendFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    final conf = widget.conf;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              PaperCard(
                stamp: l.paperStamp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (conf.isTeam)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: TeamBadge(),
                        ),
                      ),
                    _row(context, l.paperDate, fmtShortDate(conf.dateTime, lang)),
                    _row(context, l.paperTime,
                        '${fmtAmpm(conf.startTime, lang)} ~ ${fmtAmpm(conf.endTime, lang)}'),
                    _row(context, l.paperSite, conf.siteName),
                    _row(context, l.paperOrderer,
                        conf.contact != null && conf.contact!.isNotEmpty
                            ? '${conf.companyName} · ${conf.contact}'
                            : conf.companyName),
                    _row(context, l.paperWork, conf.workDescription),
                    if (conf.equipmentSection != null &&
                        (conf.equipmentSection!['name'] ?? '').toString().isNotEmpty)
                      _row(context, l.paperEquipment,
                          '${conf.equipmentSection!['name']}${conf.equipmentSection!['vehicleNumber'] != null ? ' · ${conf.equipmentSection!['vehicleNumber']}' : ''}'),
                    const SizedBox(height: 8),
                    Divider(color: c.border),
                    const SizedBox(height: 8),
                    if (conf.isTeam)
                      for (final raw in (conf.teamEntries ?? const []))
                        if (raw is Map)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      '${raw['name'] ?? ''} · ${l.qtyGongsu(formatGongsu((raw['quantity'] as num?) ?? 0))}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: c.ink2)),
                                ),
                                Text(formatMoney((raw['amount'] as num?) ?? 0, lang),
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: c.ink,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ])),
                              ],
                            ),
                          ),
                    if (!conf.isTeam && conf.baseUnit != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(l.confUnitPrice,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: c.ink2)),
                            const Spacer(),
                            Text(
                                '${formatMoney(conf.baseRate, lang)} × ${l.qtyGongsu(formatGongsu(conf.baseQuantity))}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: c.ink2,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ])),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Text(l.paperTotal,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.ink)),
                        const Spacer(),
                        Text(formatMoney(conf.total, lang),
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: c.ink,
                                fontFeatures: const [FontFeature.tabularFigures()])),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SignStatus(conf: conf),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.border)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                PrimaryButton(
                  label: conf.status == 'DRAFT' ? l.confSaveSend : l.confReshare,
                  icon: Icons.send_rounded,
                  loading: _sending,
                  onPressed: _send,
                ),
                const SizedBox(height: 8),
                Text(
                    conf.businessId != null
                        ? l.confSendToLinked
                        : l.confSendViaShare,
                    style: TextStyle(fontSize: 13, color: c.ink3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(k,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c.ink2)),
          ),
          Expanded(
            child: Text(v,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
          ),
        ],
      ),
    );
  }
}

class _SignStatus extends StatelessWidget {
  final Confirmation conf;
  const _SignStatus({required this.conf});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final signed = conf.status == 'SIGNED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: signed ? c.deposited.withValues(alpha: 0.1) : c.surface2,
        border: Border.all(color: signed ? c.deposited.withValues(alpha: 0.4) : c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(signed ? Icons.verified_rounded : Icons.draw_outlined,
              size: 20, color: signed ? c.deposited : c.ink3),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                signed
                    ? l.paperSignedBy(conf.signerName ?? l.confCounterparty)
                    : conf.status == 'SENT'
                        ? l.confSentWaitingSign
                        : l.confDraftBeforeSend,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: signed ? c.deposited : c.ink2)),
          ),
        ],
      ),
    );
  }
}
