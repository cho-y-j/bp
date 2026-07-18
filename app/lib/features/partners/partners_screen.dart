import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
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

  /// 수동 추가 시트 — 저장 성공 시 목록 갱신 + 안내.
  Future<void> _openAddSheet(BuildContext context) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddPartnerSheet(),
    );
    if (saved == true && context.mounted) {
      ref.invalidate(partnersProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l.partnerAdded)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final async = ref.watch(partnersProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: Text(l.partnersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        backgroundColor: c.primary,
        foregroundColor: c.primaryInk,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.partnersAdd,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
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
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 96),
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
    // 확인서를 쓴 적 없는(자동 통계가 없는) 거래처 — 통계 대신 "기록 없음".
    final noRecord = p.confirmationCount == 0 && p.outstanding <= 0;
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
                    // 미수 잔액 강조 / 정산 완료 / 기록 없음.
                    if (noRecord)
                      Text(l.partnerNoRecord,
                          style: TextStyle(fontSize: 13, color: c.ink3))
                    else if (settled)
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
                if (noRecord)
                  // 확인서 기록이 없는 수동 거래처 — 전화번호만(있으면) 표시.
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: c.ink3),
                      const SizedBox(width: 4),
                      Text(
                          (p.phone ?? '').trim().isEmpty
                              ? l.partnerNoPhone
                              : p.phone!,
                          style: TextStyle(fontSize: 12.5, color: c.ink2)),
                    ],
                  )
                else
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

/// 수동 거래처 추가 시트 — 이름(필수) + 전화·사업자번호·이메일·메모(선택).
class _AddPartnerSheet extends ConsumerStatefulWidget {
  const _AddPartnerSheet();
  @override
  ConsumerState<_AddPartnerSheet> createState() => _AddPartnerSheetState();
}

class _AddPartnerSheetState extends ConsumerState<_AddPartnerSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bizNumber = TextEditingController();
  final _email = TextEditingController();
  final _memo = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bizNumber.dispose();
    _email.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.partnerNameRequired)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(partnersRepoProvider).create(
            name: name,
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            bizNumber:
                _bizNumber.text.trim().isEmpty ? null : _bizNumber.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      // 중복(409)은 전용 문구로, 그 외는 서버 메시지.
      messenger.showSnackBar(SnackBar(
          content: Text(e.status == 409 ? l.partnerDuplicate : e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Padding(
      padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.partnersAdd,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
            const SizedBox(height: 14),
            _field(_name, '${l.partnerNameLabel} *',
                textInputAction: TextInputAction.next),
            const SizedBox(height: 10),
            _field(_phone, l.partnerPhoneLabel,
                keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _field(_bizNumber, l.partnerBizNumber,
                keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _field(_email, l.partnerEmail,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _field(_memo, l.partnerMemo, maxLines: 3),
            const SizedBox(height: 18),
            PrimaryButton(
              label: l.partnerSave,
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctl, String label,
      {TextInputType? keyboard,
      int maxLines = 1,
      TextInputAction? textInputAction}) {
    final c = context.c;
    return TextField(
      controller: ctl,
      keyboardType: keyboard,
      maxLines: maxLines,
      textInputAction: textInputAction,
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
