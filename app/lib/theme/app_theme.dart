import 'package:flutter/material.dart';
import 'app_colors.dart';

/// DESIGN-UI.md 원칙을 ThemeData 로. 본문 17px, 시스템 폰트(외부 다운로드 금지),
/// tabular figures, radius 카드14/버튼12, 터치 최소 48/ CTA 56.
class AppTheme {
  static const _tnum = [FontFeature.tabularFigures()];

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    // 시스템 폰트: iOS 는 SF/Apple SD Gothic Neo, Android 는 Roboto (fontFamily 미지정)
    final text = _textTheme(c);
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.primaryInk,
        surface: c.surface,
        onSurface: c.ink,
        error: c.receivable,
      ),
      extensions: [c],
      textTheme: text,
      dividerColor: c.border,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: c.ink,
        titleTextStyle: text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
      ),
      iconTheme: IconThemeData(color: c.ink, size: 24),
      cardColor: c.surface,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(color: c.bg, fontSize: 15),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: c.ink3, fontSize: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.primary, width: 1.6),
        ),
      ),
    );
  }

  static TextTheme _textTheme(AppColors c) {
    TextStyle s(double size, FontWeight w,
            {Color? color, bool tnum = false, double? h}) =>
        TextStyle(
          fontSize: size,
          fontWeight: w,
          color: color ?? c.ink,
          height: h,
          letterSpacing: -0.1,
          fontFeatures: tnum ? _tnum : null,
        );
    return TextTheme(
      // Display(금액/합계): 800
      displaySmall: s(30, FontWeight.w800, tnum: true),
      headlineMedium: s(24, FontWeight.w800, tnum: true),
      titleLarge: s(20, FontWeight.w800),
      titleMedium: s(17, FontWeight.w700),
      bodyLarge: s(17, FontWeight.w400, h: 1.45), // 본문 17px
      bodyMedium: s(15, FontWeight.w500, color: c.ink2, h: 1.4),
      bodySmall: s(13, FontWeight.w500, color: c.ink2),
      labelLarge: s(14, FontWeight.w700, color: c.ink2),
      labelMedium: s(13, FontWeight.w600, color: c.ink3),
    );
  }
}

/// tabular-figures 숫자 스타일 헬퍼.
const kTabularFigures = [FontFeature.tabularFigures()];
