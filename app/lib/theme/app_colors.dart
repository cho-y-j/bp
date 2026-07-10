import 'package:flutter/material.dart';

/// DESIGN-UI.md / mockup-v1.html 토큰을 그대로 옮긴 시맨틱 컬러 세트.
/// ThemeExtension 으로 노출해 위젯에서 `context.c` 로 접근한다.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color primaryPress;
  final Color primaryInk; // 오렌지 배경 위 글자
  final Color accentText; // 흰/어두운 배경 위 오렌지 텍스트
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color receivable; // 미수(받을 돈)
  final Color receivableBadge;
  final Color deposited; // 입금(받은 돈)
  final Color depositedBadge;
  final Color border;
  final Color borderStrong;
  final Color warnBg;
  final Color warnBorder;
  final Color warnInk;
  final Color fieldBg;

  const AppColors({
    required this.primary,
    required this.primaryPress,
    required this.primaryInk,
    required this.accentText,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.receivable,
    required this.receivableBadge,
    required this.deposited,
    required this.depositedBadge,
    required this.border,
    required this.borderStrong,
    required this.warnBg,
    required this.warnBorder,
    required this.warnInk,
    required this.fieldBg,
  });

  static const light = AppColors(
    primary: Color(0xFFF4770C),
    primaryPress: Color(0xFFD9680A),
    primaryInk: Color(0xFF241304),
    accentText: Color(0xFFB54708),
    ink: Color(0xFF1A2233),
    ink2: Color(0xFF55607A),
    ink3: Color(0xFF616D89),
    bg: Color(0xFFF7F6F3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFBFAF7),
    receivable: Color(0xFFC2410C),
    receivableBadge: Color(0xFFA83809),
    deposited: Color(0xFF15803D),
    depositedBadge: Color(0xFF0F6B32),
    border: Color(0xFFE2DFD8),
    borderStrong: Color(0xFFD2CCC0),
    warnBg: Color(0xFFFDEFE2),
    warnBorder: Color(0xFFF3C79E),
    warnInk: Color(0xFF9A3B12),
    fieldBg: Color(0xFFFAF9F6),
  );

  static const dark = AppColors(
    primary: Color(0xFFFB8C2E),
    primaryPress: Color(0xFFE5791F),
    primaryInk: Color(0xFF241304),
    accentText: Color(0xFFFB8C2E),
    ink: Color(0xFFEEF2F8),
    ink2: Color(0xFFAEB8CB),
    ink3: Color(0xFF8A94A8),
    bg: Color(0xFF131B2A),
    surface: Color(0xFF1A2334),
    surface2: Color(0xFF212C40),
    receivable: Color(0xFFFB9B54),
    receivableBadge: Color(0xFFFB9B54),
    deposited: Color(0xFF56D98A),
    depositedBadge: Color(0xFF56D98A),
    border: Color(0xFF2C3852),
    borderStrong: Color(0xFF3A4767),
    warnBg: Color(0xFF3A2A17),
    warnBorder: Color(0xFF6A4A24),
    warnInk: Color(0xFFF4B571),
    fieldBg: Color(0xFF212C40),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryPress,
    Color? primaryInk,
    Color? accentText,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? receivable,
    Color? receivableBadge,
    Color? deposited,
    Color? depositedBadge,
    Color? border,
    Color? borderStrong,
    Color? warnBg,
    Color? warnBorder,
    Color? warnInk,
    Color? fieldBg,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryPress: primaryPress ?? this.primaryPress,
      primaryInk: primaryInk ?? this.primaryInk,
      accentText: accentText ?? this.accentText,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      receivable: receivable ?? this.receivable,
      receivableBadge: receivableBadge ?? this.receivableBadge,
      deposited: deposited ?? this.deposited,
      depositedBadge: depositedBadge ?? this.depositedBadge,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      warnBg: warnBg ?? this.warnBg,
      warnBorder: warnBorder ?? this.warnBorder,
      warnInk: warnInk ?? this.warnInk,
      fieldBg: fieldBg ?? this.fieldBg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPress: Color.lerp(primaryPress, other.primaryPress, t)!,
      primaryInk: Color.lerp(primaryInk, other.primaryInk, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      receivable: Color.lerp(receivable, other.receivable, t)!,
      receivableBadge: Color.lerp(receivableBadge, other.receivableBadge, t)!,
      deposited: Color.lerp(deposited, other.deposited, t)!,
      depositedBadge: Color.lerp(depositedBadge, other.depositedBadge, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      warnBg: Color.lerp(warnBg, other.warnBg, t)!,
      warnBorder: Color.lerp(warnBorder, other.warnBorder, t)!,
      warnInk: Color.lerp(warnInk, other.warnInk, t)!,
      fieldBg: Color.lerp(fieldBg, other.fieldBg, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
}
