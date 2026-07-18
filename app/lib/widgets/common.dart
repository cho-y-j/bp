import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../models/models.dart';

/// 종이 확인서 시그니처 카드 — 상단 절취선(perforation)·스탬프 + 본문.
class PaperCard extends StatelessWidget {
  final String stamp;
  final Widget child;
  final EdgeInsets padding;
  const PaperCard({
    super.key,
    required this.stamp,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A1A2233),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Perforation(stamp: stamp),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _Perforation extends StatelessWidget {
  final String stamp;
  const _Perforation({required this.stamp});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 2),
              painter: _DashedLinePainter(c.borderStrong),
            ),
          ),
          Text(
            stamp,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: c.accentText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const dash = 5.0, gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

/// 섹션 제목 + 우측 링크.
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: c.ink2)),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// 공통 네트워크/로드 실패 표시 — raw 예외 대신 친화 메시지 + "다시 시도" 버튼.
///
/// [onRetry] 는 보통 해당 provider 를 `ref.invalidate` 한다.
/// [boxed] 가 true 면 카드(테두리) 안에, false 면 중앙 정렬 텍스트 스택으로 그린다.
class ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  final String? title;
  final String? subtitle;
  final bool boxed;
  const ErrorRetry({
    super.key,
    required this.onRetry,
    this.title,
    this.subtitle,
    this.boxed = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final title = this.title ?? l.errorConnTitle;
    final subtitle = this.subtitle ?? l.errorConnSubtitle;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          boxed ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 20, color: c.ink3),
            const SizedBox(width: 8),
            Flexible(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: c.ink)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: boxed ? TextAlign.start : TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: c.ink2)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: Icon(Icons.refresh_rounded, size: 18, color: c.ink),
          label: Text(l.retry,
              style: TextStyle(
                  color: c.ink, fontSize: 15, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c.borderStrong),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
    if (!boxed) return content;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: content,
    );
  }
}

/// D-day 배지. status 로 색을 나눈다.
class DdayBadge extends StatelessWidget {
  final int? dday;
  final String status; // PENDING/PARTIAL/PAID/OVERDUE
  final String label;
  const DdayBadge({super.key, required this.dday, required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Color bg, fg;
    IconData? icon;
    if (status == 'PAID') {
      bg = c.deposited.withValues(alpha: 0.12);
      fg = c.depositedBadge;
      icon = Icons.check_rounded;
    } else if (status == 'OVERDUE') {
      bg = c.warnBg;
      fg = c.warnInk;
      icon = Icons.warning_amber_rounded;
    } else if (dday != null && dday! <= 7) {
      bg = c.receivable.withValues(alpha: 0.12);
      fg = c.receivableBadge;
      icon = Icons.schedule_rounded;
    } else {
      bg = c.ink2.withValues(alpha: 0.12);
      fg = c.ink2;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: status == 'OVERDUE' ? Border.all(color: c.warnBorder) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

/// 서명 완료 도장(印) 박스 — 종이 확인서의 시각적 클라이맥스.
/// [signImageDataUrl] 이 있으면 실제 손글씨 획(PNG)을 흰 종이 칩에 렌더,
/// 없으면 서명자명을 각인한 붉은 도장 원으로 대체(폴백).
class SignatureSeal extends StatelessWidget {
  final String signerName;
  final String? signedAtText;
  final String? signImageDataUrl;
  const SignatureSeal({
    super.key,
    required this.signerName,
    this.signedAtText,
    this.signImageDataUrl,
  });

  Uint8List? _decode(String? dataUrl) {
    if (dataUrl == null || !dataUrl.contains(',')) return null;
    try {
      return base64Decode(dataUrl.split(',').last);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final name = signerName.trim().isEmpty ? l.confCounterparty : signerName.trim();
    // 도장 각인 텍스트 — 2~3자 이름은 그대로, 길면 앞 두 글자.
    final chars = name.characters;
    final sealText = chars.length <= 3 ? name : chars.take(2).toString();
    final stroke = _decode(signImageDataUrl);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.deposited.withValues(alpha: 0.06),
        border: Border.all(color: c.deposited.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 실제 손글씨 획(있으면) → 흰 종이 칩 / 없으면 붉은 각인 도장.
          if (stroke != null)
            Container(
              width: 96,
              height: 58,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: c.receivable.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.memory(stroke, fit: BoxFit.contain),
            )
          else
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.receivable.withValues(alpha: 0.08),
                border: Border.all(color: c.receivable, width: 2.4),
              ),
              child: Transform.rotate(
                angle: -0.1,
                child: Text(
                  sealText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: sealText.characters.length >= 3 ? 15 : 19,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: c.receivable,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: c.depositedBadge),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(l.paperSignedBy(name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: c.depositedBadge)),
                    ),
                  ],
                ),
                if (signedAtText != null && signedAtText!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(signedAtText!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.ink3,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 팀(반장) 확인서 배지.
class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_2_outlined, size: 13, color: c.accentText),
          const SizedBox(width: 3),
          Text(context.l.ledgerTeamBadge,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: c.accentText)),
        ],
      ),
    );
  }
}

/// 지급 신뢰도 배지 칩 (P3a). EXCELLENT/GOOD 만 노출(부정 라벨 없음).
/// [showAvg] 가 true 면 평균 지급일을 함께 표기.
class PaymentBadgeChip extends StatelessWidget {
  final PaymentBadge badge;
  final bool showAvg;
  const PaymentBadgeChip(this.badge, {super.key, this.showAvg = true});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;
    final excellent = badge.grade == 'EXCELLENT';
    final bg = excellent
        ? c.deposited.withValues(alpha: 0.12)
        : c.primary.withValues(alpha: 0.12);
    final fg = excellent ? c.depositedBadge : c.accentText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(excellent ? '⚡ ${l.badgeExcellent}' : l.badgeGood,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: fg)),
          if (showAvg) ...[
            const SizedBox(width: 5),
            Text(l.badgeAvgDays(badge.avgDays.round()),
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.85),
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ],
      ),
    );
  }
}

/// 미수/입금 금액 라인 (색+아이콘+텍스트 병행 — 색맹 대응).
class MoneyLine extends StatelessWidget {
  final num amount;
  final bool received; // true=입금(초록,체크), false=미수(빨강,아이콘)
  final double size;
  const MoneyLine(this.amount, {super.key, required this.received, this.size = 17});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = received ? c.deposited : c.receivable;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(received ? Icons.check_circle_outline_rounded : Icons.south_west_rounded,
            size: size - 2, color: color),
        const SizedBox(width: 4),
        Text(formatGrouped(amount, context.lang),
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

/// 56px CTA 기본 버튼.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryButton(
      {super.key, required this.label, this.icon, this.onPressed, this.loading = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryInk,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: c.primaryInk))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 21), const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// 경고 배너 (만료 임박 등).
class WarnBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const WarnBanner({super.key, required this.title, this.subtitle, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: c.warnBg,
            border: Border.all(color: c.warnBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: c.warnInk, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: c.warnInk)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(subtitle!,
                            style: TextStyle(
                                fontSize: 13,
                                color: c.warnInk.withValues(alpha: 0.85))),
                      ),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right_rounded, color: c.warnInk),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상태별 텍스트 색을 위한 헬퍼.
Color statusColor(BuildContext context, String status) {
  final c = context.c;
  switch (status) {
    case 'PAID':
      return c.deposited;
    case 'OVERDUE':
      return c.warnInk;
    default:
      return c.receivable;
  }
}

/// 회사 아바타(이니셜 or 완납 체크).
class CompanyAvatar extends StatelessWidget {
  final String name;
  final bool paid;
  const CompanyAvatar({super.key, required this.name, this.paid = false});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: paid
            ? c.deposited.withValues(alpha: 0.15)
            : c.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: paid
          ? Icon(Icons.check_rounded, color: c.deposited, size: 22)
          : Text(name.isNotEmpty ? name.characters.first : '?',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: c.accentText)),
    );
  }
}

/// 통일 D-day 규칙(전 화면 공용): 임박 "D-N" · 당일 "D-day" · 지남 "+N일".
/// 부호 혼용(D+N)을 없애고 지남은 항상 "+N일" 하나로 표기한다.
String ddayUnified(AppLocalizations l, int? dday) {
  if (dday == null) return '';
  if (dday >= 0) return ddayLabel(dday); // "D-N" / "D-day"
  return l.ddayOverdue(-dday); // "+N일"
}

/// 수금(장부) D-day 텍스트 — 완납/지남은 의미 라벨, 임박은 "수금 D-N".
String ddayText(AppLocalizations l, int? dday, String status) {
  if (status == 'PAID') return l.statusDeposited;
  if (status == 'OVERDUE' || (dday != null && dday < 0)) {
    return dday == null ? l.statusOverdue : ddayUnified(l, dday); // 지남 → "+N일"
  }
  if (dday == null) return '';
  return l.collectDday(ddayUnified(l, dday)); // "수금 D-N"
}
