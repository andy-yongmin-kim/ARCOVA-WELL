import 'package:flutter/material.dart';

/// Arcova Well Theme — clean minimal wellness identity.
/// Navy + sage + warm gold on a soft off-white canvas.
class AppTheme {
  // 🎨 Arcova Color Palette
  static const Color primaryColor = Color(0xFF1A2B48); // Navy
  static const Color accentColor = Color(0xFF86A69D); // Sage
  static const Color secondaryColor = Color(0xFF86A69D);
  static const Color tertiaryColor = Color(0xFFD68C45); // Warm gold
  static const Color backgroundColor = Color(0xFFFFFCF9); // Warm off-white
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color successColor = Color(0xFF2DC897);
  static const Color textPrimary = Color(0xFF1A2B48); // Navy text
  static const Color textSecondary = Color(0xFF64748B); // Slate gray
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color surfaceSoftColor = Color(0xFFF1F4F3);
  static const Color surfaceStrongColor = Color(0xFFE2E8F0);

  // Wellness metric accent colors
  static const Color sleepColor = Color(0xFF6C8AE4); // Indigo-blue
  static const Color stepsColor = Color(0xFF86A69D); // Sage
  static const Color activeColor = Color(0xFFD68C45); // Gold
  static const Color heartColor = Color(0xFFE26D7A); // Soft rose
  static const Color moodColor = Color(0xFFB08FD8); // Soft violet

  // Simple Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A2B48), Color(0xFF2D4470)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF86A69D), Color(0xFF6E8F86)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGlossGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Simple Card Shadow (clean, like app.tsx)
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.3),
      offset: const Offset(0, 8),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  /// Wellness metric color getter
  static Color getMetricColor(String metric) {
    switch (metric) {
      case 'sleep':
        return sleepColor;
      case 'steps':
        return stepsColor;
      case 'active':
        return activeColor;
      case 'heart':
        return heartColor;
      case 'mood':
        return moodColor;
      default:
        return accentColor;
    }
  }

  /// Simple shadow for backward compatibility
  static List<BoxShadow> buildNeumorphicShadow({
    Offset lightOffset = const Offset(-8, -8),
    Offset darkOffset = const Offset(10, 10),
    double blur = 24,
    double spread = 0,
    double lightOpacity = 0.8,
    double darkOpacity = 0.15,
  }) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: darkOpacity),
        offset: darkOffset,
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  /// Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      // Clean AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 26),
      ),

      // Clean Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          textStyle: const TextStyle(
            inherit: false,
            fontFamily: 'Pretendard',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            inherit: false,
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Clean Cards
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Filter Chips
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSoftColor,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // FAB Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSoftColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 16,
          color: textMuted,
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // SnackBars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 15,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Text Styles (inherit: false pairs with darkTheme for AnimatedTheme lerp)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.8,
        ),
        displaySmall: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 16,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 13,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),

      scaffoldBackgroundColor: backgroundColor,
      dividerColor: surfaceStrongColor,
    );
  }

  // Dark Theme Colors (Arcova deep navy)
  static const Color darkBackgroundColor = Color(0xFF0E1624);
  static const Color darkSurfaceColor = Color(0xFF172338);
  static const Color darkCardColor = Color(0xFF1E2D45);
  static const Color darkTextPrimary = Color(0xFFEDF2F4);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      brightness: Brightness.dark,
      primaryColor: accentColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        onPrimary: primaryColor,
        secondary: tertiaryColor,
        surface: darkSurfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary, size: 26),
      ),
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          textStyle: const TextStyle(
            inherit: false,
            fontFamily: 'Pretendard',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            inherit: false,
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCardColor,
        selectedColor: accentColor,
        labelStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 16,
          color: darkTextSecondary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCardColor,
        contentTextStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 15,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: darkTextPrimary,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.8,
        ),
        displaySmall: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
        headlineSmall: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        titleSmall: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 16,
          color: darkTextPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: darkTextPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 13,
          color: darkTextSecondary,
        ),
        labelLarge: TextStyle(
          inherit: false,
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerColor: Colors.white12,
    );
  }
}
