import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../core/format.dart';
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
      appBar: AppBar(title: const Text('작업확인서')),
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
    try {
      final repo = ref.read(repoProvider);
      final res = await repo.send(widget.conf.id);
      final url = res['url']?.toString() ?? '';
      final linked = res['linked'] == true;
      if (!mounted) return;
      if (linked) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연결된 사업장에 전송했어요.')));
      } else {
        await shareConfirmationLink(context, widget.conf, url);
      }
      ref.invalidate(_confDetailProvider(widget.conf.id));
      invalidateAll(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('전송 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final conf = widget.conf;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              PaperCard(
                stamp: '작 업 확 인 서',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(context, '작업일', formatShortDate(conf.dateTime)),
                    _row(context, '시간', '${conf.startTime} ~ ${conf.endTime}'),
                    _row(context, '현장', conf.siteName),
                    _row(context, '지시자',
                        conf.contact != null && conf.contact!.isNotEmpty
                            ? '${conf.companyName} · ${conf.contact}'
                            : conf.companyName),
                    _row(context, '작업 내용', conf.workDescription),
                    if (conf.equipmentSection != null &&
                        (conf.equipmentSection!['name'] ?? '').toString().isNotEmpty)
                      _row(context, '장비',
                          '${conf.equipmentSection!['name']}${conf.equipmentSection!['vehicleNumber'] != null ? ' · ${conf.equipmentSection!['vehicleNumber']}' : ''}'),
                    const SizedBox(height: 8),
                    Divider(color: c.border),
                    const SizedBox(height: 8),
                    if (conf.baseUnit != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('단가',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: c.ink2)),
                            const Spacer(),
                            Text(
                                '${formatWon(conf.baseRate)} × ${formatGongsu(conf.baseQuantity)}${conf.baseUnit}',
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
                        Text('받을 금액',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.ink)),
                        const Spacer(),
                        Text.rich(TextSpan(children: [
                          TextSpan(text: formatWon(conf.total)),
                          const TextSpan(text: ' 원', style: TextStyle(fontSize: 17)),
                        ]),
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
                  label: conf.status == 'DRAFT' ? '저장하고 보내기' : '다시 공유하기',
                  icon: Icons.send_rounded,
                  loading: _sending,
                  onPressed: _send,
                ),
                const SizedBox(height: 8),
                Text(
                    conf.businessId != null
                        ? '연결된 사업장으로 전송됩니다'
                        : '공유 시트(카카오톡 등)로 링크를 보낼 수 있어요',
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
                    ? '${conf.signerName ?? '상대'} 서명 완료'
                    : conf.status == 'SENT'
                        ? '전송됨 · 상대 서명 대기 중'
                        : '작성됨 · 전송 전',
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
