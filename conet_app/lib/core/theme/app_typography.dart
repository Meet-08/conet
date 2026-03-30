import 'package:flutter/material.dart';

final class AppTypographyTokens {
  const AppTypographyTokens._();

  static const String fontFamilyPrimary = 'Inter';

  static const double size11 = 11;
  static const double size12 = 12;
  static const double size13 = 13;
  static const double size14 = 14;
  static const double size15 = 15;
  static const double size16 = 16;
  static const double size18 = 18;
  static const double size20 = 20;
  static const double size22 = 22;
  static const double size24 = 24;
  static const double size28 = 28;
  static const double size30 = 30;
  static const double size32 = 32;

  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  static const double lineHeight14 = 14;
  static const double lineHeight16 = 16;
  static const double lineHeight18 = 18;
  static const double lineHeight22 = 22;
  static const double lineHeight24 = 24;
  static const double lineHeight26 = 26;
  static const double lineHeight28 = 28;
  static const double lineHeight30 = 30;
  static const double lineHeight32 = 32;
  static const double lineHeight36 = 36;
  static const double lineHeight38 = 38;
  static const double lineHeight40 = 40;

  static const double letterSpacingNone = 0;
  static const double letterSpacingMicro = 0.01;
  static const double letterSpacingUppercase = 0.04;
}

final class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle display = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size30,
    fontWeight: AppTypographyTokens.weightBold,
    height: AppTypographyTokens.lineHeight38 / AppTypographyTokens.size30,
    letterSpacing: AppTypographyTokens.letterSpacingNone,
  );

  static const TextStyle headingH1 = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size22,
    fontWeight: AppTypographyTokens.weightSemibold,
    height: AppTypographyTokens.lineHeight30 / AppTypographyTokens.size22,
  );

  static const TextStyle headingH2 = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size20,
    fontWeight: AppTypographyTokens.weightSemibold,
    height: AppTypographyTokens.lineHeight28 / AppTypographyTokens.size20,
  );

  static const TextStyle headingH3 = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size18,
    fontWeight: AppTypographyTokens.weightMedium,
    height: AppTypographyTokens.lineHeight26 / AppTypographyTokens.size18,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size16,
    fontWeight: AppTypographyTokens.weightRegular,
    height: AppTypographyTokens.lineHeight24 / AppTypographyTokens.size16,
  );

  static const TextStyle bodyDefault = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size15,
    fontWeight: AppTypographyTokens.weightRegular,
    height: AppTypographyTokens.lineHeight22 / AppTypographyTokens.size15,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size13,
    fontWeight: AppTypographyTokens.weightRegular,
    height: AppTypographyTokens.lineHeight18 / AppTypographyTokens.size13,
  );

  static const TextStyle label = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size14,
    fontWeight: AppTypographyTokens.weightMedium,
    height: AppTypographyTokens.lineHeight18 / AppTypographyTokens.size14,
  );

  static const TextStyle button = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size15,
    fontWeight: AppTypographyTokens.weightMedium,
    height: AppTypographyTokens.lineHeight22 / AppTypographyTokens.size15,
  );

  static const TextStyle link = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size15,
    fontWeight: AppTypographyTokens.weightMedium,
    height: AppTypographyTokens.lineHeight22 / AppTypographyTokens.size15,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size12,
    fontWeight: AppTypographyTokens.weightRegular,
    height: AppTypographyTokens.lineHeight16 / AppTypographyTokens.size12,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: AppTypographyTokens.fontFamilyPrimary,
    fontSize: AppTypographyTokens.size11,
    fontWeight: AppTypographyTokens.weightRegular,
    height: AppTypographyTokens.lineHeight14 / AppTypographyTokens.size11,
    letterSpacing: AppTypographyTokens.letterSpacingMicro,
  );

  static TextTheme textTheme(Color color) {
    return TextTheme(
      displayLarge: display.copyWith(color: color),
      headlineLarge: headingH1.copyWith(color: color),
      headlineMedium: headingH2.copyWith(color: color),
      headlineSmall: headingH3.copyWith(color: color),
      bodyLarge: bodyLarge.copyWith(color: color),
      bodyMedium: bodyDefault.copyWith(color: color),
      bodySmall: bodySmall.copyWith(color: color),
      labelLarge: button.copyWith(color: color),
      labelMedium: label.copyWith(color: color),
      labelSmall: caption.copyWith(color: color),
      titleSmall: link.copyWith(color: color),
    );
  }
}
