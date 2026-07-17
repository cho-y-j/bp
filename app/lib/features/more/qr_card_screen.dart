import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../l10n/l10n_ext.dart';
import '../../models/models.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../sms/sms_share.dart';

/// 내 QR 명함 (P3b) — 로컬 QR 렌더 + 링크 공유 + 한 줄 소개/공개 토글 + 링크 재발급.
class QrCardScreen extends ConsumerStatefulWidget {
  const QrCardScreen({super.key});
  @override
  ConsumerState<QrCardScreen> createState() => _QrCardScreenState();
}

class _QrCardScreenState extends ConsumerState<QrCardScreen> {
  late final TextEditingController _intro;
  bool _introInit = false;
  bool _savingIntro = false;
  bool _rotating = false;
  bool _togglingExpose = false;

  @override
  void initState() {
    super.initState();
    _intro = TextEditingController();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _saveIntro() async {
    setState(() => _savingIntro = true);
    final l = context.l;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .saveCard(intro: _intro.text);
      ref.invalidate(myCardProvider);
      messenger.showSnackBar(SnackBar(content: Text(l.qrCardIntroSaved)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingIntro = false);
    }
  }

  Future<void> _toggleExpose(bool value) async {
    setState(() => _togglingExpose = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .saveCard(enabled: value);
      ref.invalidate(myCardProvider);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _togglingExpose = false);
    }
  }

  Future<void> _rotate() async {
    final l = context.l;
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.qrCardRotate),
        content: Text(l.qrCardRotateConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.qrCardRotateConfirmBtn,
                  style: TextStyle(color: c.receivable))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _rotating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(repoProvider).rotateCard();
      ref.invalidate(myCardProvider);
      messenger.showSnackBar(SnackBar(content: Text(l.qrCardRotated)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _rotating = false);
    }
  }

  Future<void> _sms(String url) async {
    await composeSms(context, ref,
        recipients: const [], body: context.l.smsCardShareBody(url));
  }

  Future<void> _share(String url) async {
    final l = context.l;
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      '${l.qrCardMenuTitle}\n$url',
      subject: l.qrCardMenuTitle,
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final cardAsync = ref.watch(myCardProvider);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text(l.qrCardTitle,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
      ),
      body: cardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e is ApiException ? e.message : '$e',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.ink2)),
          ),
        ),
        data: (card) {
          if (!_introInit) {
            _intro.text = card.intro ?? '';
            _introInit = true;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              _QrCard(card: card),
              const SizedBox(height: 12),
              _UrlRow(url: card.url, onShare: () => _share(card.url)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _sms(card.url),
                icon: const Icon(Icons.sms_outlined, size: 18),
                label: Text(l.smsSendSms,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: c.accentText,
                  side: BorderSide(color: c.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(l.qrCardViewCount(card.viewCount),
                    style: TextStyle(fontSize: 12.5, color: c.ink3)),
              ),
              const SizedBox(height: 18),
              _DocStatusSection(status: card.docStatus),
              const SizedBox(height: 18),
              _sectionLabel(l.qrCardIntroLabel),
              _introEditor(card),
              const SizedBox(height: 18),
              _sectionLabel(l.qrCardExposeTitle),
              _exposeToggle(card),
              const SizedBox(height: 18),
              _rotateButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.c.ink3)),
      );

  Widget _introEditor(CardData card) {
    final c = context.c;
    final l = context.l;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _intro,
            maxLength: 80,
            style: TextStyle(fontSize: 16, color: c.ink),
            decoration: InputDecoration(
              hintText: l.qrCardIntroPlaceholder,
              filled: true,
              fillColor: c.fieldBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border)),
            ),
          ),
          const SizedBox(height: 6),
          PrimaryButton(
            label: l.save,
            icon: Icons.check_rounded,
            loading: _savingIntro,
            onPressed: _saveIntro,
          ),
        ],
      ),
    );
  }

  Widget _exposeToggle(CardData card) {
    final c = context.c;
    final l = context.l;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 22, color: c.ink2),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.qrCardExposeTitle,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: c.ink)),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(l.qrCardExposeSub,
                          style: TextStyle(fontSize: 13, color: c.ink2)),
                    ),
                  ],
                ),
              ),
              if (_togglingExpose)
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: c.primary))
              else
                Switch(
                    value: card.enabled,
                    onChanged: _toggleExpose,
                    activeTrackColor: c.primary),
            ],
          ),
          if (!card.enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              child: Row(
                children: [
                  Icon(Icons.visibility_off_outlined,
                      size: 16, color: c.warnInk),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l.qrCardHiddenHint,
                        style: TextStyle(fontSize: 12.5, color: c.warnInk)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _rotateButton() {
    final c = context.c;
    final l = context.l;
    return OutlinedButton.icon(
      onPressed: _rotating ? null : _rotate,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        side: BorderSide(color: c.border),
        foregroundColor: c.ink2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: _rotating
          ? SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: c.ink2))
          : const Icon(Icons.autorenew_rounded, size: 20),
      label: Text(l.qrCardRotate,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}

/// QR 코드 카드 — 로컬 렌더(네트워크 없음). 스캔용으로 항상 밝은 배경.
class _QrCard extends StatelessWidget {
  final CardData card;
  const _QrCard({required this.card});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          if ((card.name ?? '').isNotEmpty)
            Text(card.name!,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c.ink)),
          if (card.industryTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in card.industryTags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 12,
                              color: c.ink2,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          if ((card.intro ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(card.intro!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.ink2)),
            ),
          const SizedBox(height: 18),
          // QR: 항상 흰 배경 + 검은 모듈 (스캔 신뢰성). 로컬 렌더.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            child: QrImageView(
              data: card.url,
              version: QrVersions.auto,
              size: 220,
              gapless: false,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square, color: Color(0xFF111111)),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF111111)),
            ),
          ),
          const SizedBox(height: 12),
          Text(l.qrCardScanHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: c.ink3)),
        ],
      ),
    );
  }
}

/// 명함 링크 + 공유 버튼.
class _UrlRow extends StatelessWidget {
  final String url;
  final VoidCallback onShare;
  const _UrlRow({required this.url, required this.onShare});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 18, color: c.ink3),
          const SizedBox(width: 8),
          Expanded(
            child: Text(url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: c.ink2)),
          ),
          TextButton.icon(
            onPressed: onShare,
            style: TextButton.styleFrom(foregroundColor: c.accentText),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: Text(l.share,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// 서류 유효 상태 — 유효하면 긍정 칩, 문제 서류가 있으면 소유자에게 안내.
class _DocStatusSection extends StatelessWidget {
  final CardDocStatus status;
  const _DocStatusSection({required this.status});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final children = <Widget>[];
    if (status.valid) {
      children.add(Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: c.deposited.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded,
                  size: 15, color: c.depositedBadge),
              const SizedBox(width: 5),
              Text(l.qrCardDocValid,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.depositedBadge)),
            ],
          ),
        ),
      ));
    }
    if (status.expiredDocs.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(Text(l.qrCardDocProblem,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: c.warnInk)));
      for (final d in status.expiredDocs) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 16, color: c.warnInk),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  d.expiryDate != null
                      ? '${d.type} · ${l.qrCardDocExpiryLabel(fmtShortDate(d.expiryDate!, context.lang))}'
                      : d.type,
                  style: TextStyle(fontSize: 13.5, color: c.ink2),
                ),
              ),
            ],
          ),
        ));
      }
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
