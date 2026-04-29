import 'package:flutter/material.dart';

class ThemeHelper {
  // Reactive boolean to switch between dark mode (true) and light mode (false).
  static final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(
    true,
  );

  static bool get isDarkMode => isDarkModeNotifier.value;
  static void toggleTheme() {
    isDarkModeNotifier.value = !isDarkModeNotifier.value;
  }

  // Dark Mode Colors (Original Website Colors)
  static const Color _darkBackgroundClr = Color(0xFF2B3141);
  static const Color _darkPrimaryClr = Color(0xFF2B3141);
  static const Color _darkDrawerClr = Color(0xff383E51);
  static const Color _darkLightPrimaryClr = Color(0xff585E70);
  static const Color _darkIconBoxClr = Color(0xFF657296);
  static const Color _darkLightPinkClr = Color(0xFF858FCA);
  static const Color _darkLightBlueClr = Color(0xFF9FAFD2);
  static const Color _darkLightGreenClr = Color(0xFF8ECAD5);
  static const Color _darkWhiteClr = Colors.white;

  // Light Mode Colors (Relevant Colors Added)
  static const Color _lightBackgroundClr = Color(0xFFF9FAFB);
  static const Color _lightPrimaryClr = Color(0xFFF3F4F6);
  static const Color _lightDrawerClr = Color(0xFFE5E7EB);
  static const Color _lightLightPrimaryClr = Color(0xFFD1D5DB);
  static const Color _lightIconBoxClr = Color(0xFF9CA3AF);
  static const Color _lightLightPinkClr = Color(0xFFEF4444);
  static const Color _lightLightBlueClr = Color(0xFF3B82F6);
  static const Color _lightLightGreenClr = Color(0xFF10B981);
  static const Color _lightWhiteClr = Color(0xFF111827);

  static const Color _lightYellowClr = Color(0xFFF59E0B);

  // Getters for specific colors depending on the active theme mode
  static Color get backgroundClr =>
      isDarkMode ? _darkBackgroundClr : _lightBackgroundClr;
  static Color get primaryClr =>
      isDarkMode ? _darkPrimaryClr : _lightPrimaryClr;
  static Color get drawerClr => isDarkMode ? _darkDrawerClr : _lightDrawerClr;
  static Color get lightPrimaryClr =>
      isDarkMode ? _darkLightPrimaryClr : _lightLightPrimaryClr;
  static Color get iconBoxClr =>
      isDarkMode ? _darkIconBoxClr : const Color.fromARGB(255, 202, 216, 252);
  static Color get lightPinkClr =>
      isDarkMode ? _darkLightPinkClr : _lightLightPinkClr;
  static Color get lightBlueClr =>
      isDarkMode ? _darkLightBlueClr : _lightLightBlueClr;
  static Color get lightGreenClr =>
      isDarkMode ? _darkLightGreenClr : _lightLightGreenClr;
  static Color get whiteClr => isDarkMode ? _darkWhiteClr : _lightWhiteClr;

  static Color get buttonTextClr => isDarkMode ? _darkWhiteClr : _lightWhiteClr;

  static Color get buttonBgClr =>
      isDarkMode ? const Color(0xFF455168) : const Color(0xFFD8E2FC);

  static Color get queryBoxClr =>
      isDarkMode ? _darkLightPrimaryClr : Colors.white;

  static get myMessageBubble =>
      isDarkMode ? _darkLightPrimaryClr : const Color(0xFFD8E2FC);

  static get logoUrl =>
      isDarkMode ? "assets/icons/logo-D.svg" : 'assets/icons/logo-D-dark.svg';

  static Color get successColor => _lightLightGreenClr;

  static Color get errorColor => _lightLightPinkClr;

  static Color get warningColor => _lightYellowClr;

  static Color get infoColor => _lightLightBlueClr;

  static Color get tertiaryColor => _lightLightBlueClr;
}

// Global getters for backward compatibility throughout the project
Color get backgroundClr => ThemeHelper.backgroundClr;
Color get primaryClr => ThemeHelper.primaryClr;
Color get drawerClr => ThemeHelper.drawerClr;
Color get lightPrimaryClr => ThemeHelper.lightPrimaryClr;
Color get iconBoxClr => ThemeHelper.iconBoxClr;
Color get lightPinkClr => ThemeHelper.lightPinkClr;
Color get lightBlueClr => ThemeHelper.lightBlueClr;
Color get lightGreenClr => ThemeHelper.lightGreenClr;
Color get whiteClr => ThemeHelper.whiteClr;
