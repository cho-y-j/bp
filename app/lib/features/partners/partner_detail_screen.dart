import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/partners.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../confirmation/confirmation_form_screen.dart';
import '../sms/quick_send_screen.dart';
import '../sms/sms_share.dart';

/// 거래처 상세 — 요약 + 액션(문자/전화/확인서) + 보강 정보 편집(수기만).
class PartnerDetailScreen extends ConsumerStatefulWidget {
  final Partner partner;
  const PartnerDetailScreen({super.key, required this.partner});
  @override
  ConsumerState<PartnerDetailScreen> createState() =>
      _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends ConsumerState<PartnerDetailScreen> {
  late Partner _partner; // 편집 저장 시 로컬 갱신.
  late final TextEditingController _alias;
  late final TextEditingController _bizNumber;
  late final TextEditingController _email;
  late final TextEditingController _memo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _partner = widget.partner;
    _alias = TextEditingController(text: _partner.alias ?? '');
    _bizNumber = TextEditingController(text: _partner.bizNumber ?? '');
    _email = TextEditingController(text: _partner.email ?? '');
    _memo = TextEditingController(text: _partner.memo ?? '');
  }

  @override
  void dispose() {
    _alias.dispose();
    _bizNumber.dispose();
    _email.dispose();
    _memo.dispose();
    super.dispose();
  }

  bool get _hasPhone => (_partner.phone ?? '').trim().isNotEmpty;

  Future<void> _save() async {
    final id = _partner.id;
    if (id == null) return;
    setState(() => _saving = true);
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await ref.read(partnersRepoProvider).patch(
            id,
            alias: _alias.text.trim(),
            bizNumber: _bizNumber.text.trim(),
            email: _email.text.trim(),
            memo: _memo.text.trim(),
          );
      ref.invalidate(partnersProvider);
      if (!mounted) return;
      // 서버 응답에는 집계(미수 등)가 없으므로 보강 필드만 로컬 반영.
      setState(() {
        _partner = Partner(
          id: _partner.id,
          businessId: _partner.businessId,
          linked: _partner.linked,
          name: _partner.name,
          phone: updated.phone ?? _partner.phone,
          alias: updated.alias,
          bizNumber: updated.bizNumber,
          email: updated.email,
          memo: updated.memo,
          confirmationCount: _partner.confirmationCount,
          outstanding: _partner.outstanding,
          paid: _partner.paid,
          lastWorkedDate: _partner.lastWorkedDate,
        );
      });
      messenger.showSnackBar(SnackBar(content: Text(l.partnerSaved)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openSms() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuickSendScreen(
        presetRecipient: _partner.phone,
        presetRecipientName: _partner.name,
      ),
    ));
  }

  void _call() {
    launchCallAndRecord(context, ref,
        name: _partner.name, phone: _partner.phone ?? '');
  }

  void _writeConfirmation() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConfirmationFormScreen(
        prefillCompany: _partner.name,
        prefillContact: _partner.phone,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final lang = context.lang;
    final p = _partner;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(p.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            // ── 요약 카드 ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(p.name,
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: c.ink)),
                      ),
                      if (p.linked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(l.partnerLinkedBadge,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.accentText)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(l.partnerOutstandingLabel,
                      style: TextStyle(fontSize: 13, color: c.ink2)),
                  const SizedBox(height: 2),
                  Text(
                    p.outstanding <= 0
                        ? l.partnerSettledLabel
                        : formatMoney(p.outstanding, lang),
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: p.outstanding <= 0 ? c.ink3 : c.receivable,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Stat(label: l.partnerPaidLabel, value: formatMoney(p.paid, lang)),
                      _Stat(
                          label: l.partnerConfLabel,
                          value: '${p.confirmationCount}'),
                      _Stat(
                          label: l.partnerLastWorked,
                          value: p.lastWorkedDate == null
                              ? '-'
                              : _fmt(p.lastWorkedDate!, lang)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── 액션 3버튼 ──
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.sms_outlined,
                    label: l.partnerActionSms,
                    enabled: _hasPhone,
                    onTap: _openSms,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.call_outlined,
                    label: l.partnerActionCall,
                    enabled: _hasPhone,
                    onTap: _call,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.edit_document,
                    label: l.partnerActionWriteConf,
                    enabled: true,
                    onTap: _writeConfirmation,
                  ),
                ),
              ],
            ),
            if (!_hasPhone)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2),
                child: Text(l.partnerNoPhone,
                    style: TextStyle(fontSize: 12.5, color: c.ink3)),
              ),
            const SizedBox(height: 20),
            // ── 보강 정보 편집(수기만) ──
            Text(l.partnerEditTitle,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 10),
            if (!p.isManual)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface2,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 18, color: c.ink3),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.partnerLinkedNote,
                          style: TextStyle(fontSize: 13.5, color: c.ink2)),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _field(_alias, l.partnerAlias),
                    const SizedBox(height: 10),
                    _field(_bizNumber, l.partnerBizNumber,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 10),
                    _field(_email, l.partnerEmail,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _field(_memo, l.partnerMemo, maxLines: 3),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: l.partnerSave,
                      icon: Icons.check_rounded,
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(String ymd, String lang) {
    final d = DateTime.tryParse(ymd);
    return d == null ? ymd : fmtShortDate(d, lang);
  }

  Widget _field(TextEditingController ctl, String label,
      {TextInputType? keyboard, int maxLines = 1}) {
    final c = context.c;
    return TextField(
      controller: ctl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: TextStyle(fontSize: 16, color: c.ink),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: c.fieldBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.border)),
      ),
    );
  }
}

/// 요약 보조 스탯(라벨 + 값).
class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: c.ink3)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// 액션 버튼(아이콘 + 라벨, 비활성 지원).
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: enabled ? c.surface : c.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: enabled ? c.accentText : c.ink3),
              const SizedBox(height: 6),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: enabled ? c.ink : c.ink3)),
            ],
          ),
        ),
      ),
    );
  }
}
