import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimaryColor = Color(0xFF1ABC9C);
const Color kPrimaryDark = Color(0xFF16A085);
const Color kBackground = Color(0xFFF5F5F5);
const Color kCardBackground = Colors.white;
const Color kTextPrimary = Color(0xFF333333);
const Color kTextSecondary = Color(0xFF999999);
const Color kCodeBackground = Color(0xFF2D3436);
const Color kCodeText = Color(0xFF00FF00);
const Color kStarColor = Color(0xFFFFC107);

// ─── ダークモード用カラー ────────────────────────────────────────────────────
const Color kDarkBackground = Color(0xFF121212);
const Color kDarkSurface = Color(0xFF1E1E1E);
const Color kDarkSurface2 = Color(0xFF2A2A2A);
const Color kDarkTextPrimary = Color(0xFFE8E8E8);
const Color kDarkTextSecondary = Color(0xFF9E9E9E);

// ─── テーマ判定ヘルパー ──────────────────────────────────────────────────────
extension ThemeContextX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  /// カード背景色（ライト: 白、ダーク: kDarkSurface）
  Color get cardBg => isDark ? kDarkSurface : Colors.white;
  /// サブカード背景（ライト: F5F5F5、ダーク: kDarkSurface2）
  Color get subCardBg => isDark ? kDarkSurface2 : const Color(0xFFF5F5F5);
  /// プライマリテキスト
  Color get textPrimary => isDark ? kDarkTextPrimary : kTextPrimary;
  /// セカンダリテキスト
  Color get textSecondary => isDark ? kDarkTextSecondary : kTextSecondary;
  /// 薄い影
  Color get shadowColor =>
      isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.06);
  /// ボーダー色
  Color get borderColor =>
      isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2);
}

// ─── ライトテーマ ────────────────────────────────────────────────────────────
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    primary: kPrimaryColor,
    secondary: kPrimaryDark,
    surface: kCardBackground,
  ),
  scaffoldBackgroundColor: kBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.notoSansJp(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: GoogleFonts.notoSansJp(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: kCardBackground,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: kPrimaryColor,
    unselectedItemColor: kTextSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: kPrimaryColor,
    unselectedLabelColor: kTextSecondary,
    indicatorColor: kPrimaryColor,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF9F9F9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
    hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.notoSansJp(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: kTextPrimary,
    ),
    displayMedium: GoogleFonts.notoSansJp(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: kTextPrimary,
    ),
    displaySmall: GoogleFonts.notoSansJp(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: kTextPrimary,
    ),
    headlineMedium: GoogleFonts.notoSansJp(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    headlineSmall: GoogleFonts.notoSansJp(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    titleLarge: GoogleFonts.notoSansJp(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    titleMedium: GoogleFonts.notoSansJp(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: kTextPrimary,
    ),
    bodyLarge: GoogleFonts.notoSansJp(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: kTextPrimary,
    ),
    bodyMedium: GoogleFonts.notoSansJp(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: kTextPrimary,
    ),
    bodySmall: GoogleFonts.notoSansJp(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: kTextSecondary,
    ),
    labelLarge: GoogleFonts.notoSansJp(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: kPrimaryColor,
    ),
  ),
);

// ─── ダークテーマ ────────────────────────────────────────────────────────────
final ThemeData darkAppTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    primary: kPrimaryColor,
    secondary: kPrimaryDark,
    surface: kDarkSurface,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: kDarkBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.notoSansJp(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: GoogleFonts.notoSansJp(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  cardTheme: CardThemeData(
    color: kDarkSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    tileColor: kDarkSurface,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kDarkSurface,
    selectedItemColor: kPrimaryColor,
    unselectedItemColor: kDarkTextSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: kPrimaryColor,
    unselectedLabelColor: kDarkTextSecondary,
    indicatorColor: kPrimaryColor,
  ),
  dividerColor: Colors.white12,
  dialogTheme: const DialogThemeData(backgroundColor: kDarkSurface),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: kDarkSurface,
    modalBackgroundColor: kDarkSurface,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kDarkSurface2,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF424242)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF424242)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
    hintStyle: const TextStyle(color: Color(0xFF757575)),
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.notoSansJp(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: kDarkTextPrimary,
    ),
    displayMedium: GoogleFonts.notoSansJp(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: kDarkTextPrimary,
    ),
    displaySmall: GoogleFonts.notoSansJp(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: kDarkTextPrimary,
    ),
    headlineMedium: GoogleFonts.notoSansJp(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: kDarkTextPrimary,
    ),
    headlineSmall: GoogleFonts.notoSansJp(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: kDarkTextPrimary,
    ),
    titleLarge: GoogleFonts.notoSansJp(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: kDarkTextPrimary,
    ),
    titleMedium: GoogleFonts.notoSansJp(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: kDarkTextPrimary,
    ),
    bodyLarge: GoogleFonts.notoSansJp(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: kDarkTextPrimary,
    ),
    bodyMedium: GoogleFonts.notoSansJp(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: kDarkTextPrimary,
    ),
    bodySmall: GoogleFonts.notoSansJp(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: kDarkTextSecondary,
    ),
    labelLarge: GoogleFonts.notoSansJp(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: kPrimaryColor,
    ),
  ),
);
