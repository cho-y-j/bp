import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../widgets/common.dart';
import '../sms/sms_share.dart';
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

  /// 문자로 보내기 — 수기 상대 전화 자동 수신인 + 서명 부탁 본문 프리필.
  Future<void> _sendSms() async {
    final l = context.l;
    final conf = widget.conf;
    final url = confirmationUrl(conf.shareToken);
    final phone = extractPhone(conf.contact);
    final name = (conf.contact != null &&
            conf.contact!.trim().isNotEmpty &&
            phone == null)
        ? conf.contact!.trim()
        : null;
    final body = name != null
        ? l.smsConfBodyNamed(name, conf.siteName, url)
        : l.smsConfBodyPlain(conf.siteName, url);
    await composeSms(
      context,
      ref,
      recipients: phone != null ? [phone] : const [],
      body: body,
    );
  }

  Future<void> _call() async {
    final phone = extractPhone(widget.conf.contact);
    if (phone == null) return;
    await launchCallAndRecord(context, ref,
        name: widget.conf.companyName, phone: phone);
  }

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
                  icon: Icons.send_outlined,
                  loading: _sending,
                  onPressed: _send,
                ),
                const SizedBox(height: 8),
                // 카톡 공유(재전송=기존) 옆에 문자로 보내기 / 전화 걸기.
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _sendSms,
                        icon: const Icon(Icons.sms_outlined, size: 18),
                        label: Text(l.smsSendSms,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          foregroundColor: c.accentText,
                          side: BorderSide(color: c.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                        ),
                      ),
                    ),
                    if (extractPhone(conf.contact) != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _call,
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: Text(l.callButtonLabel,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            foregroundColor: c.ink2,
                            side: BorderSide(color: c.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11)),
                          ),
                        ),
                      ),
                    ],
                  ],
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
    if (signed) {
      return SignatureSeal(
        signerName: conf.signerName ?? l.confCounterparty,
        signedAtText: conf.signedAt,
        signImageDataUrl: conf.signImageDataUrl,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.draw_outlined, size: 20, color: c.ink3),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                conf.status == 'SENT'
                    ? l.confSentWaitingSign
                    : l.confDraftBeforeSend,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: c.ink2)),
          ),
        ],
      ),
    );
  }
}
