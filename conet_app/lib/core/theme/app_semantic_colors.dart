import 'package:conet_app/core/theme/app_primitives.dart';
import 'package:flutter/material.dart';

class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textError,
    required this.textSuccess,
    required this.textWarning,
    required this.textInfo,
    required this.textBrand,
    required this.textOnBrand,
    required this.textOnError,
    required this.textOnSuccess,
    required this.textOnWarning,
    required this.textOnInfo,
    required this.textLink,
    required this.textLinkHover,
    required this.textLinkVisited,
    required this.textInverse,
    required this.textSelected,
    required this.borderDefault,
    required this.borderSubtle,
    required this.borderStrong,
    required this.borderDisabled,
    required this.borderFocus,
    required this.borderBrand,
    required this.borderError,
    required this.borderErrorStrong,
    required this.borderSuccess,
    required this.borderWarning,
    required this.borderInfo,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundTertiary,
    required this.backgroundDisabled,
    required this.backgroundHover,
    required this.backgroundPressed,
    required this.backgroundSelected,
    required this.backgroundBrand,
    required this.backgroundError,
    required this.backgroundSuccess,
    required this.backgroundWarning,
    required this.backgroundInfo,
    required this.backgroundBackdrop,
    required this.backgroundInverse,
    required this.iconPrimary,
    required this.iconSecondary,
    required this.iconTertiary,
    required this.iconDisabled,
    required this.iconBrand,
    required this.iconOnBrand,
    required this.iconOnError,
    required this.iconOnSuccess,
    required this.iconOnWarning,
    required this.iconOnInfo,
    required this.iconError,
    required this.iconSuccess,
    required this.iconWarning,
    required this.iconInfo,
    required this.iconInverse,
    required this.iconSelected,
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.surfaceSunken,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textError;
  final Color textSuccess;
  final Color textWarning;
  final Color textInfo;
  final Color textBrand;
  final Color textOnBrand;
  final Color textOnError;
  final Color textOnSuccess;
  final Color textOnWarning;
  final Color textOnInfo;
  final Color textLink;
  final Color textLinkHover;
  final Color textLinkVisited;
  final Color textInverse;
  final Color textSelected;

  final Color borderDefault;
  final Color borderSubtle;
  final Color borderStrong;
  final Color borderDisabled;
  final Color borderFocus;
  final Color borderBrand;
  final Color borderError;
  final Color borderErrorStrong;
  final Color borderSuccess;
  final Color borderWarning;
  final Color borderInfo;

  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundTertiary;
  final Color backgroundDisabled;
  final Color backgroundHover;
  final Color backgroundPressed;
  final Color backgroundSelected;
  final Color backgroundBrand;
  final Color backgroundError;
  final Color backgroundSuccess;
  final Color backgroundWarning;
  final Color backgroundInfo;
  final Color backgroundBackdrop;
  final Color backgroundInverse;

  final Color iconPrimary;
  final Color iconSecondary;
  final Color iconTertiary;
  final Color iconDisabled;
  final Color iconBrand;
  final Color iconOnBrand;
  final Color iconOnError;
  final Color iconOnSuccess;
  final Color iconOnWarning;
  final Color iconOnInfo;
  final Color iconError;
  final Color iconSuccess;
  final Color iconWarning;
  final Color iconInfo;
  final Color iconInverse;
  final Color iconSelected;

  final Color surfaceBase;
  final Color surfaceRaised;
  final Color surfaceOverlay;
  final Color surfaceSunken;

  static const AppSemanticColors light = AppSemanticColors(
    textPrimary: NeutralPaletteLight.c700,
    textSecondary: NeutralPaletteLight.c500,
    textTertiary: NeutralPaletteLight.c400,
    textDisabled: NeutralPaletteLight.c300,
    textError: StatusErrorPalette.c500,
    textSuccess: StatusSuccessPalette.c500,
    textWarning: StatusWarningPalette.c500,
    textInfo: StatusInfoPalette.c500,
    textBrand: BrandPalette.c700,
    textOnBrand: Color(0xFF18181B),
    textOnError: Colors.white,
    textOnSuccess: Colors.white,
    textOnWarning: Color(0xFF18181B),
    textOnInfo: Colors.white,
    textLink: AccentPalette.c600,
    textLinkHover: AccentPalette.c700,
    textLinkVisited: AccentPalette.c800,
    textInverse: NeutralPaletteLight.c0,
    textSelected: AccentPalette.c700,
    borderDefault: NeutralPaletteLight.c200,
    borderSubtle: NeutralPaletteLight.c100,
    borderStrong: NeutralPaletteLight.c400,
    borderDisabled: NeutralPaletteLight.c100,
    borderFocus: AccentPalette.c500,
    borderBrand: BrandPalette.c500,
    borderError: StatusErrorPalette.c300,
    borderErrorStrong: StatusErrorPalette.c500,
    borderSuccess: StatusSuccessPalette.c300,
    borderWarning: StatusWarningPalette.c300,
    borderInfo: StatusInfoPalette.c300,
    backgroundPrimary: NeutralPaletteLight.c0,
    backgroundSecondary: NeutralPaletteLight.c50,
    backgroundTertiary: NeutralPaletteLight.c100,
    backgroundDisabled: NeutralPaletteLight.c100,
    backgroundHover: NeutralPaletteLight.c50,
    backgroundPressed: NeutralPaletteLight.c100,
    backgroundSelected: AccentPalette.c100,
    backgroundBrand: BrandPalette.c500,
    backgroundError: StatusErrorPalette.c50,
    backgroundSuccess: StatusSuccessPalette.c50,
    backgroundWarning: StatusWarningPalette.c50,
    backgroundInfo: StatusInfoPalette.c50,
    backgroundBackdrop: BackdropPalette.black50,
    backgroundInverse: NeutralPaletteLight.c900,
    iconPrimary: NeutralPaletteLight.c700,
    iconSecondary: NeutralPaletteLight.c500,
    iconTertiary: NeutralPaletteLight.c400,
    iconDisabled: NeutralPaletteLight.c300,
    iconBrand: BrandPalette.c600,
    iconOnBrand: Color(0xFF18181B),
    iconOnError: Colors.white,
    iconOnSuccess: Colors.white,
    iconOnWarning: Color(0xFF18181B),
    iconOnInfo: Colors.white,
    iconError: StatusErrorPalette.c500,
    iconSuccess: StatusSuccessPalette.c500,
    iconWarning: StatusWarningPalette.c500,
    iconInfo: StatusInfoPalette.c500,
    iconInverse: NeutralPaletteLight.c0,
    iconSelected: AccentPalette.c600,
    surfaceBase: NeutralPaletteLight.c0,
    surfaceRaised: NeutralPaletteLight.c50,
    surfaceOverlay: NeutralPaletteLight.c0,
    surfaceSunken: NeutralPaletteLight.c100,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    textPrimary: NeutralPaletteDark.c100,
    textSecondary: NeutralPaletteDark.c300,
    textTertiary: NeutralPaletteDark.c500,
    textDisabled: NeutralPaletteDark.c600,
    textError: StatusErrorPalette.c300,
    textSuccess: StatusSuccessPalette.c300,
    textWarning: StatusWarningPalette.c300,
    textInfo: StatusInfoPalette.c300,
    textBrand: BrandPalette.c300,
    textOnBrand: Color(0xFF18181B),
    textOnError: Colors.white,
    textOnSuccess: Colors.white,
    textOnWarning: Color(0xFF18181B),
    textOnInfo: Colors.white,
    textLink: AccentPalette.c400,
    textLinkHover: AccentPalette.c300,
    textLinkVisited: AccentPalette.c500,
    textInverse: NeutralPaletteDark.c900,
    textSelected: AccentPalette.c300,
    borderDefault: NeutralPaletteDark.c700,
    borderSubtle: NeutralPaletteDark.c800,
    borderStrong: NeutralPaletteDark.c500,
    borderDisabled: NeutralPaletteDark.c800,
    borderFocus: AccentPalette.c400,
    borderBrand: BrandPalette.c400,
    borderError: StatusErrorPalette.c500,
    borderErrorStrong: StatusErrorPalette.c400,
    borderSuccess: StatusSuccessPalette.c500,
    borderWarning: StatusWarningPalette.c500,
    borderInfo: StatusInfoPalette.c500,
    backgroundPrimary: NeutralPaletteDark.c0,
    backgroundSecondary: NeutralPaletteDark.c50,
    backgroundTertiary: NeutralPaletteDark.c100,
    backgroundDisabled: NeutralPaletteDark.c800,
    backgroundHover: NeutralPaletteDark.c700,
    backgroundPressed: NeutralPaletteDark.c800,
    backgroundSelected: AccentPalette.c800,
    backgroundBrand: BrandPalette.c400,
    backgroundError: StatusErrorPalette.c800,
    backgroundSuccess: StatusSuccessPalette.c800,
    backgroundWarning: StatusWarningPalette.c800,
    backgroundInfo: StatusInfoPalette.c800,
    backgroundBackdrop: BackdropPalette.black70,
    backgroundInverse: NeutralPaletteDark.c0,
    iconPrimary: NeutralPaletteDark.c100,
    iconSecondary: NeutralPaletteDark.c300,
    iconTertiary: NeutralPaletteDark.c400,
    iconDisabled: NeutralPaletteDark.c600,
    iconBrand: BrandPalette.c400,
    iconOnBrand: Color(0xFF18181B),
    iconOnError: Colors.white,
    iconOnSuccess: Colors.white,
    iconOnWarning: Color(0xFF18181B),
    iconOnInfo: Colors.white,
    iconError: StatusErrorPalette.c300,
    iconSuccess: StatusSuccessPalette.c300,
    iconWarning: StatusWarningPalette.c300,
    iconInfo: StatusInfoPalette.c300,
    iconInverse: NeutralPaletteDark.c900,
    iconSelected: AccentPalette.c400,
    surfaceBase: NeutralPaletteDark.c0,
    surfaceRaised: NeutralPaletteDark.c100,
    surfaceOverlay: NeutralPaletteDark.c200,
    surfaceSunken: NeutralPaletteDark.c900,
  );

  @override
  AppSemanticColors copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? textError,
    Color? textSuccess,
    Color? textWarning,
    Color? textInfo,
    Color? textBrand,
    Color? textOnBrand,
    Color? textOnError,
    Color? textOnSuccess,
    Color? textOnWarning,
    Color? textOnInfo,
    Color? textLink,
    Color? textLinkHover,
    Color? textLinkVisited,
    Color? textInverse,
    Color? textSelected,
    Color? borderDefault,
    Color? borderSubtle,
    Color? borderStrong,
    Color? borderDisabled,
    Color? borderFocus,
    Color? borderBrand,
    Color? borderError,
    Color? borderErrorStrong,
    Color? borderSuccess,
    Color? borderWarning,
    Color? borderInfo,
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? backgroundTertiary,
    Color? backgroundDisabled,
    Color? backgroundHover,
    Color? backgroundPressed,
    Color? backgroundSelected,
    Color? backgroundBrand,
    Color? backgroundError,
    Color? backgroundSuccess,
    Color? backgroundWarning,
    Color? backgroundInfo,
    Color? backgroundBackdrop,
    Color? backgroundInverse,
    Color? iconPrimary,
    Color? iconSecondary,
    Color? iconTertiary,
    Color? iconDisabled,
    Color? iconBrand,
    Color? iconOnBrand,
    Color? iconOnError,
    Color? iconOnSuccess,
    Color? iconOnWarning,
    Color? iconOnInfo,
    Color? iconError,
    Color? iconSuccess,
    Color? iconWarning,
    Color? iconInfo,
    Color? iconInverse,
    Color? iconSelected,
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceOverlay,
    Color? surfaceSunken,
  }) {
    return AppSemanticColors(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      textError: textError ?? this.textError,
      textSuccess: textSuccess ?? this.textSuccess,
      textWarning: textWarning ?? this.textWarning,
      textInfo: textInfo ?? this.textInfo,
      textBrand: textBrand ?? this.textBrand,
      textOnBrand: textOnBrand ?? this.textOnBrand,
      textOnError: textOnError ?? this.textOnError,
      textOnSuccess: textOnSuccess ?? this.textOnSuccess,
      textOnWarning: textOnWarning ?? this.textOnWarning,
      textOnInfo: textOnInfo ?? this.textOnInfo,
      textLink: textLink ?? this.textLink,
      textLinkHover: textLinkHover ?? this.textLinkHover,
      textLinkVisited: textLinkVisited ?? this.textLinkVisited,
      textInverse: textInverse ?? this.textInverse,
      textSelected: textSelected ?? this.textSelected,
      borderDefault: borderDefault ?? this.borderDefault,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      borderDisabled: borderDisabled ?? this.borderDisabled,
      borderFocus: borderFocus ?? this.borderFocus,
      borderBrand: borderBrand ?? this.borderBrand,
      borderError: borderError ?? this.borderError,
      borderErrorStrong: borderErrorStrong ?? this.borderErrorStrong,
      borderSuccess: borderSuccess ?? this.borderSuccess,
      borderWarning: borderWarning ?? this.borderWarning,
      borderInfo: borderInfo ?? this.borderInfo,
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundTertiary: backgroundTertiary ?? this.backgroundTertiary,
      backgroundDisabled: backgroundDisabled ?? this.backgroundDisabled,
      backgroundHover: backgroundHover ?? this.backgroundHover,
      backgroundPressed: backgroundPressed ?? this.backgroundPressed,
      backgroundSelected: backgroundSelected ?? this.backgroundSelected,
      backgroundBrand: backgroundBrand ?? this.backgroundBrand,
      backgroundError: backgroundError ?? this.backgroundError,
      backgroundSuccess: backgroundSuccess ?? this.backgroundSuccess,
      backgroundWarning: backgroundWarning ?? this.backgroundWarning,
      backgroundInfo: backgroundInfo ?? this.backgroundInfo,
      backgroundBackdrop: backgroundBackdrop ?? this.backgroundBackdrop,
      backgroundInverse: backgroundInverse ?? this.backgroundInverse,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
      iconTertiary: iconTertiary ?? this.iconTertiary,
      iconDisabled: iconDisabled ?? this.iconDisabled,
      iconBrand: iconBrand ?? this.iconBrand,
      iconOnBrand: iconOnBrand ?? this.iconOnBrand,
      iconOnError: iconOnError ?? this.iconOnError,
      iconOnSuccess: iconOnSuccess ?? this.iconOnSuccess,
      iconOnWarning: iconOnWarning ?? this.iconOnWarning,
      iconOnInfo: iconOnInfo ?? this.iconOnInfo,
      iconError: iconError ?? this.iconError,
      iconSuccess: iconSuccess ?? this.iconSuccess,
      iconWarning: iconWarning ?? this.iconWarning,
      iconInfo: iconInfo ?? this.iconInfo,
      iconInverse: iconInverse ?? this.iconInverse,
      iconSelected: iconSelected ?? this.iconSelected,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }

    return AppSemanticColors(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textError: Color.lerp(textError, other.textError, t)!,
      textSuccess: Color.lerp(textSuccess, other.textSuccess, t)!,
      textWarning: Color.lerp(textWarning, other.textWarning, t)!,
      textInfo: Color.lerp(textInfo, other.textInfo, t)!,
      textBrand: Color.lerp(textBrand, other.textBrand, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      textOnError: Color.lerp(textOnError, other.textOnError, t)!,
      textOnSuccess: Color.lerp(textOnSuccess, other.textOnSuccess, t)!,
      textOnWarning: Color.lerp(textOnWarning, other.textOnWarning, t)!,
      textOnInfo: Color.lerp(textOnInfo, other.textOnInfo, t)!,
      textLink: Color.lerp(textLink, other.textLink, t)!,
      textLinkHover: Color.lerp(textLinkHover, other.textLinkHover, t)!,
      textLinkVisited: Color.lerp(textLinkVisited, other.textLinkVisited, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      textSelected: Color.lerp(textSelected, other.textSelected, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderDisabled: Color.lerp(borderDisabled, other.borderDisabled, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderBrand: Color.lerp(borderBrand, other.borderBrand, t)!,
      borderError: Color.lerp(borderError, other.borderError, t)!,
      borderErrorStrong: Color.lerp(
        borderErrorStrong,
        other.borderErrorStrong,
        t,
      )!,
      borderSuccess: Color.lerp(borderSuccess, other.borderSuccess, t)!,
      borderWarning: Color.lerp(borderWarning, other.borderWarning, t)!,
      borderInfo: Color.lerp(borderInfo, other.borderInfo, t)!,
      backgroundPrimary: Color.lerp(
        backgroundPrimary,
        other.backgroundPrimary,
        t,
      )!,
      backgroundSecondary: Color.lerp(
        backgroundSecondary,
        other.backgroundSecondary,
        t,
      )!,
      backgroundTertiary: Color.lerp(
        backgroundTertiary,
        other.backgroundTertiary,
        t,
      )!,
      backgroundDisabled: Color.lerp(
        backgroundDisabled,
        other.backgroundDisabled,
        t,
      )!,
      backgroundHover: Color.lerp(backgroundHover, other.backgroundHover, t)!,
      backgroundPressed: Color.lerp(
        backgroundPressed,
        other.backgroundPressed,
        t,
      )!,
      backgroundSelected: Color.lerp(
        backgroundSelected,
        other.backgroundSelected,
        t,
      )!,
      backgroundBrand: Color.lerp(backgroundBrand, other.backgroundBrand, t)!,
      backgroundError: Color.lerp(backgroundError, other.backgroundError, t)!,
      backgroundSuccess: Color.lerp(
        backgroundSuccess,
        other.backgroundSuccess,
        t,
      )!,
      backgroundWarning: Color.lerp(
        backgroundWarning,
        other.backgroundWarning,
        t,
      )!,
      backgroundInfo: Color.lerp(backgroundInfo, other.backgroundInfo, t)!,
      backgroundBackdrop: Color.lerp(
        backgroundBackdrop,
        other.backgroundBackdrop,
        t,
      )!,
      backgroundInverse: Color.lerp(
        backgroundInverse,
        other.backgroundInverse,
        t,
      )!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
      iconTertiary: Color.lerp(iconTertiary, other.iconTertiary, t)!,
      iconDisabled: Color.lerp(iconDisabled, other.iconDisabled, t)!,
      iconBrand: Color.lerp(iconBrand, other.iconBrand, t)!,
      iconOnBrand: Color.lerp(iconOnBrand, other.iconOnBrand, t)!,
      iconOnError: Color.lerp(iconOnError, other.iconOnError, t)!,
      iconOnSuccess: Color.lerp(iconOnSuccess, other.iconOnSuccess, t)!,
      iconOnWarning: Color.lerp(iconOnWarning, other.iconOnWarning, t)!,
      iconOnInfo: Color.lerp(iconOnInfo, other.iconOnInfo, t)!,
      iconError: Color.lerp(iconError, other.iconError, t)!,
      iconSuccess: Color.lerp(iconSuccess, other.iconSuccess, t)!,
      iconWarning: Color.lerp(iconWarning, other.iconWarning, t)!,
      iconInfo: Color.lerp(iconInfo, other.iconInfo, t)!,
      iconInverse: Color.lerp(iconInverse, other.iconInverse, t)!,
      iconSelected: Color.lerp(iconSelected, other.iconSelected, t)!,
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
    );
  }
}

extension SemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
