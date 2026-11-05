import 'package:flutter/painting.dart';

/// Design tokens from docs/design/ui-design-brief.md section 3–5.
/// Widgets read colours, sizes and type from here, never from literals.
///
/// Colour roles are reserved: [income] and [expense] mean money in and money
/// out and nothing else; [attentionSurface] means "needs your attention" and
/// nothing else. Contrast and colour-blind separation of every pair is
/// recorded in the brief, section 3.2–3.3.
abstract final class AppColors {
  static const Color ink = Color(0xFF1C1C1A);
  static const Color inkMuted = Color(0xFF5E5E59);
  static const Color surface = Color(0xFFF7F7F5);
  static const Color surfaceSunken = Color(0xFFF0EDEA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFD6D6D1);
  static const Color outlineControl = Color(0xFF8A8A85);

  static const Color income = Color(0xFF0F766E);
  static const Color incomeTint = Color(0xFFE6F2F1);
  static const Color expense = Color(0xFFC2410C);
  static const Color expenseTint = Color(0xFFFBEAE3);

  static const Color brand = Color(0xFF1E3A8A);
  static const Color brandTint = Color(0xFFE8ECF8);

  static const Color attentionSurface = Color(0xFFFDF3D7);

  static const Color disabledFill = Color(0xFFE3E3DE);
  static const Color disabledText = Color(0xFF6E6E69);

  static const Color onFill = Color(0xFFFFFFFF);
  static const Color scrim = Color(0x801C1C1A);
}

/// 4 dp spacing grid.
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double gutter = 16;
}

abstract final class AppRadius {
  static const double control = 16;
  static const double pill = 28;
  static const double sheet = 28;
}

abstract final class AppSizes {
  /// Minimum height of every touch target.
  static const double touch = 56;
  static const double heroButton = 112;
  static const double keypadKey = 56;
  static const double iconDisc = 44;
  static const double icon = 24;
  static const double iconLarge = 28;
  static const double iconHero = 40;
  static const double iconSmall = 18;
  static const double attentionBorder = 2;
  static const double focusBorder = 2;
  static const int descriptionMax = 120;
  static const Duration suggestionDebounce = Duration(milliseconds: 250);
  static const Duration savedBanner = Duration(milliseconds: 1500);
}

/// Type scale (brief section 4). 14 sp is the floor and only for captions.
abstract final class AppText {
  /// The one type family: Roboto, Android's system font, so nothing is bundled.
  static const String family = 'Roboto';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle amountEntry = TextStyle(
    fontFamily: family,
    fontSize: 44,
    height: 52 / 44,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );
  static const TextStyle amount = TextStyle(
    fontFamily: family,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );
  static const TextStyle amountSmall = TextStyle(
    fontFamily: family,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );
  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const TextStyle label = TextStyle(
    fontFamily: family,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
  );
  static const TextStyle captionStrong = TextStyle(
    fontFamily: family,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w700,
    color: AppColors.inkMuted,
  );
  static const TextStyle keypad = TextStyle(
    fontFamily: family,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    fontFeatures: _tabular,
  );
  static const TextStyle code = TextStyle(
    fontFamily: family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    color: AppColors.ink,
  );
}
