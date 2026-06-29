import 'package:flutter/material.dart';

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
  fontFamily: 'NotoSansJP',
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(
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
  fontFamily: 'NotoSansJP',
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(
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
      borderSide: BorderSide.none,
    ),
  ),
);
