import 'package:conet_app/core/theme/app_primitives.dart';
import 'package:conet_app/core/theme/app_semantic_colors.dart';
import 'package:conet_app/core/theme/app_tokens.dart';
import 'package:conet_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

final class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
    brightness: Brightness.light,
    semantic: AppSemanticColors.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: BrandPalette.c500,
      onPrimary: NeutralPaletteLight.c900,
      primaryContainer: BrandPalette.c50,
      onPrimaryContainer: BrandPalette.c700,
      secondary: AccentPalette.c500,
      onSecondary: NeutralPaletteLight.c0,
      secondaryContainer: AccentPalette.c100,
      onSecondaryContainer: AccentPalette.c800,
      tertiary: BrandPalette.c300,
      onTertiary: NeutralPaletteLight.c900,
      tertiaryContainer: BrandPalette.c50,
      onTertiaryContainer: BrandPalette.c700,
      error: StatusErrorPalette.c500,
      onError: NeutralPaletteLight.c0,
      errorContainer: StatusErrorPalette.c50,
      onErrorContainer: StatusErrorPalette.c700,
      surface: NeutralPaletteLight.c0,
      onSurface: NeutralPaletteLight.c900,
      surfaceContainerHighest: NeutralPaletteLight.c100,
      onSurfaceVariant: NeutralPaletteLight.c500,
      outline: NeutralPaletteLight.c200,
      outlineVariant: NeutralPaletteLight.c100,
      shadow: Color(0x14000000),
      scrim: BackdropPalette.black50,
      inverseSurface: NeutralPaletteLight.c900,
      onInverseSurface: NeutralPaletteLight.c0,
      inversePrimary: BrandPalette.c400,
    ),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    semantic: AppSemanticColors.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: BrandPalette.c500,
      onPrimary: NeutralPaletteDark.c900,
      primaryContainer: BrandPalette.c900,
      onPrimaryContainer: BrandPalette.c300,
      secondary: AccentPalette.c400,
      onSecondary: NeutralPaletteDark.c900,
      secondaryContainer: AccentPalette.c800,
      onSecondaryContainer: AccentPalette.c200,
      tertiary: BrandPalette.c300,
      onTertiary: NeutralPaletteDark.c900,
      tertiaryContainer: BrandPalette.c800,
      onTertiaryContainer: BrandPalette.c100,
      error: StatusErrorPalette.c400,
      onError: NeutralPaletteDark.c900,
      errorContainer: StatusErrorPalette.c800,
      onErrorContainer: StatusErrorPalette.c300,
      surface: NeutralPaletteDark.c900,
      onSurface: NeutralPaletteDark.c50,
      surfaceContainerHighest: NeutralPaletteDark.c700,
      onSurfaceVariant: NeutralPaletteDark.c300,
      outline: NeutralPaletteDark.c700,
      outlineVariant: NeutralPaletteDark.c800,
      shadow: Color(0x33000000),
      scrim: BackdropPalette.black70,
      inverseSurface: NeutralPaletteDark.c0,
      onInverseSurface: NeutralPaletteDark.c900,
      inversePrimary: BrandPalette.c400,
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppSemanticColors semantic,
    required ColorScheme colorScheme,
  }) {
    final textTheme = AppTextStyles.textTheme(semantic.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypographyTokens.fontFamilyPrimary,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: semantic.backgroundPrimary,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: semantic.surfaceBase,
        foregroundColor: semantic.textPrimary,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingH3.copyWith(
          color: semantic.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: semantic.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: semantic.borderSubtle),
        ),
      ),
      dividerColor: semantic.borderSubtle,
      iconTheme: IconThemeData(
        color: semantic.iconPrimary,
        size: 18,
        weight: 700,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: semantic.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s12,
          vertical: AppSpace.s12,
        ),
        prefixIconColor: semantic.iconSecondary,
        suffixIconColor: semantic.iconSecondary,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        hintStyle: AppTextStyles.bodyDefault.copyWith(
          color: semantic.textTertiary,
        ),
        labelStyle: AppTextStyles.label.copyWith(color: semantic.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: semantic.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: semantic.borderFocus, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: semantic.borderErrorStrong),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: semantic.borderErrorStrong, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: semantic.backgroundBrand,
          foregroundColor: semantic.textOnBrand,
          disabledBackgroundColor: semantic.backgroundDisabled,
          disabledForegroundColor: semantic.textDisabled,
          textStyle: AppTextStyles.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: AppSpace.s12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: semantic.textPrimary,
          textStyle: AppTextStyles.button,
          side: BorderSide(color: semantic.borderDefault),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: AppSpace.s12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: semantic.textLink,
          textStyle: AppTextStyles.link,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: semantic.backgroundInverse,
        contentTextStyle: AppTextStyles.bodyDefault.copyWith(
          color: semantic.textInverse,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: semantic.backgroundSecondary,
        selectedColor: semantic.backgroundSelected,
        disabledColor: semantic.backgroundDisabled,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: semantic.textSecondary,
        ),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: semantic.textSelected,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullAll),
        side: BorderSide(color: semantic.borderDefault),
      ),
      extensions: <ThemeExtension<dynamic>>[semantic],
    );
  }
}
