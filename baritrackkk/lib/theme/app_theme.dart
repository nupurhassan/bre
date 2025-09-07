import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 New Neutral Palette
  static const Color accentBlueGrey = Color(0xFF6B7A89); // replaces primaryBlue
  static const Color accentBeige = Color(0xFFCDBCA8);    // replaces goldenYellow
  static const Color accentTaupe = Color(0xFF675C5A);    // replaces cardBackground
  static const Color neutralDark = Color(0xFF201E1F);    // replaces darkBackground
  static const Color deepRed = Color(0xFFA72218);        // error/danger

  static ThemeData darkTheme = ThemeData(
    primaryColor: accentBlueGrey,
    scaffoldBackgroundColor: neutralDark,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: accentBeige,
      ),
      iconTheme: IconThemeData(color: accentBeige),
    ),

    cardTheme: const CardThemeData(
      color: accentTaupe,
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlueGrey,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: accentBeige),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentBeige),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentBlueGrey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.all(16),
    ),
  );
}
