import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // 🎨 Primary Theme Colors
  static const Color primaryColor = Color(0xFF1565C0); // Deep Blue
  static const Color secondaryColor = Color(0xFF42A5F5); // Lighter Blue
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Gray
  static const Color cardColor = Colors.white; // Card background
  static const Color textColor = Colors.black87;
  static const Color buttonColor = primaryColor;

  // 🖋️ Define the ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _textTheme.bodyLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  // 📌 Define Global Text Styles
  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.rubik(
        fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
    titleLarge: GoogleFonts.rubik(
        fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
    bodyLarge: GoogleFonts.rubik(
        fontSize: 18, fontWeight: FontWeight.normal, color: textColor),
    bodyMedium: GoogleFonts.rubik(fontSize: 16, color: textColor),
    labelLarge: GoogleFonts.rubik(
        fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
  );

  // 📌 AppBar Theme
  static final AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: primaryColor,
    titleTextStyle: GoogleFonts.lobster(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black), // ✅ Title in black
    iconTheme: const IconThemeData(
        color: Colors.black), // ✅ Back & Menu buttons in black
  );

  // ✅ Title Text Style
  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'SuezOne',
    fontSize: 36.0,
    fontWeight: FontWeight.bold,
    color: AppColors.secondary,
  );

  // ✅ Hint Text Style
  static const TextStyle hintTextStyle = TextStyle(
    fontSize: 14.0,
    color: AppColors.textSecondary,
  );

  // ✅ Link Text Style
  static const TextStyle linkTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // ✅ Primary Button Text Style
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  // ✅ Secondary Button Text Style
  static const TextStyle secondaryButtonTextStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
  );

  // ✅ Elevated Button Style (Primary)
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    elevation: 4,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25.0),
    ),
  );

  static const TextStyle bodyText = TextStyle(
    // ✅ Add this line
    fontSize: 16.0,
    color: AppColors.textPrimary,
  );

  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
    ),
    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: AppColors.primary, // Ensure AppColors.primary exists
    fontFamily: 'SuezOne',
  );
  static const TextStyle screenTitle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: 'SuezOne',
  );

  static const TextStyle tabTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black, // Default color
  );

  static InputDecoration inputDecoration({String? hintText}) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
    );
  }

  static BoxDecoration get navigationBoxDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      );
}
