import 'package:flutter/material.dart';

/// The single source of colours, sizes and text styles. Widgets read from here, never literals.
abstract final class AppColors {
  static const Color income = Color(0xFF2E7D32);
  static const Color expense = Color(0xFFC62828);
  static const Color onIncome = Colors.white;
  static const Color onExpense = Colors.white;
  static const Color surface = Color(0xFFF7F7F5);
  static const Color card = Colors.white;
  static const Color outline = Color(0xFFD6D6D1);
  static const Color text = Color(0xFF1C1C1A);
  static const Color muted = Color(0xFF6B6B66);
  static const Color selected = Color(0xFF1C1C1A);
  static const Color onSelected = Colors.white;
  static const Color badge = Color(0xFFE8E8E3);
}

abstract final class AppSizes {
  /// Minimum touch target for every tappable control.
  static const double touch = 56;
  static const double bigButton = 112;
  static const double keypadKey = 64;
  static const double gutter = 16;
  static const double gap = 12;
  static const double smallGap = 6;
  static const double radius = 16;
  static const double chipRadius = 28;
  static const double icon = 28;
  static const double bigIcon = 40;
  static const double smallIcon = 18;
  static const double listIcon = 44;
  static const Duration debounce = Duration(milliseconds: 250);
  static const Duration savedBanner = Duration(milliseconds: 1500);
  static const int descriptionMax = 120;
}

abstract final class AppText {
  static const TextStyle body = TextStyle(
    fontSize: 18,
    color: AppColors.text,
    height: 1.3,
  );
  static const TextStyle label = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const TextStyle button = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const TextStyle amount = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle amountEntry = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );
  static const TextStyle keypad = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const TextStyle code = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    color: AppColors.text,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.muted,
  );
}

Color colorForIncome(bool income) =>
    income ? AppColors.income : AppColors.expense;
Color onColorForIncome(bool income) =>
    income ? AppColors.onIncome : AppColors.onExpense;

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.income,
    surface: AppColors.surface,
    onSurface: AppColors.text,
  );
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSizes.radius),
  );
  const minSize = Size(AppSizes.touch, AppSizes.touch);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surface,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textTheme: const TextTheme(
      bodyLarge: AppText.body,
      bodyMedium: AppText.body,
      titleLarge: AppText.title,
      labelLarge: AppText.button,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      titleTextStyle: AppText.title,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minSize,
        shape: shape,
        textStyle: AppText.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        shape: shape,
        textStyle: AppText.button,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: minSize),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      hintStyle: AppText.body.copyWith(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      contentPadding: const EdgeInsets.all(AppSizes.gutter),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
  );
}
