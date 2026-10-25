import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF586BFF);
  static const Color secondary = Color(0xFF915BFF);
  static const Color accent = Color(0xFF2DD4BF);
  static const Color lightBackground = Color(0xFFF2F5FF);
  static const Color darkBackground = Color(0xFF0C1226);
  static const Color darkCard = Color(0xFF111C33);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFDF7FF), Color(0xFFE4EDFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF0B1224), Color(0xFF111C34)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightHeaderGradient = LinearGradient(
    colors: [Color(0xFF5C6FFF), Color(0xFF8B5BFF), Color(0xFF61D2FF)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [Color(0xFF2D45A4), Color(0xFF4A38C7), Color(0xFF5C4BFF)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDEE6FF),
    onPrimaryContainer: Color(0xFF0A1440),
    secondary: secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFECE4FF),
    onSecondaryContainer: Color(0xFF200B54),
    tertiary: accent,
    onTertiary: Color(0xFF001E2A),
    tertiaryContainer: Color(0xFFCBEDFF),
    onTertiaryContainer: Color(0xFF00131C),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: lightBackground,
    onBackground: Color(0xFF0A1533),
    surface: Colors.white,
    onSurface: Color(0xFF0A1533),
    surfaceVariant: Color(0xFFE1E6FF),
    onSurfaceVariant: Color(0xFF4C5576),
    outline: Color(0xFFD0D6F5),
    outlineVariant: Color(0xFFE1E6FF),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF1B2447),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFFBECCFF),
    surfaceTint: Colors.white,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB7C7FF),
    onPrimary: Color(0xFF06133B),
    primaryContainer: Color(0xFF1F2F63),
    onPrimaryContainer: Color(0xFFE0E5FF),
    secondary: Color(0xFFB9A9FF),
    onSecondary: Color(0xFF1F0B52),
    secondaryContainer: Color(0xFF2A1C5A),
    onSecondaryContainer: Color(0xFFE6DCFF),
    tertiary: accent,
    onTertiary: Color(0xFF001B26),
    tertiaryContainer: Color(0xFF0F3144),
    onTertiaryContainer: Color(0xFFBDE9FF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: darkBackground,
    onBackground: Colors.white,
    surface: darkCard,
    onSurface: Colors.white,
    surfaceVariant: Color(0xFF1F2942),
    onSurfaceVariant: Color(0xFFBAC8F6),
    outline: Color(0xFF2E3A5C),
    outlineVariant: Color(0xFF3D4868),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFF5F7FF),
    onInverseSurface: Color(0xFF0F152F),
    inversePrimary: primary,
    surfaceTint: Colors.transparent,
  );

  static ThemeData light() {
    const scheme = _lightScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      textTheme: _textTheme(
        heading: const Color(0xFF0B1535),
        body: const Color(0xFF25304D),
        muted: const Color(0xFF7A86AE),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Color(0xFF0F172A),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: .06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE0E4FF)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primary.withValues(alpha: .12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white.withValues(alpha: .92),
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : const Color(0xFF4A5576),
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: Color(0xFFCBD3FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEF2FF),
        selectedColor: primary,
        secondarySelectedColor: primary,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: Color(0xFFE0E4FF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: const TextStyle(color: Color(0xFF9AA3BC)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFD9DEFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primary.withValues(alpha: .7)),
        ),
      ),
      dividerColor: const Color(0xFFE0E4FF),
      iconTheme: const IconThemeData(color: Color(0xFF1F2A44)),
    );
  }

  static ThemeData dark() {
    const scheme = _darkScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      textTheme: _textTheme(
        heading: Colors.white,
        body: const Color(0xFFE3E9FF),
        muted: const Color(0xFF9FB0DA),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: .5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF24304A)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: Colors.white.withValues(alpha: .08),
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFF0E1425).withValues(alpha: .95),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E2743),
        selectedColor: accent,
        secondarySelectedColor: accent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: Color(0xFF2B3658)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF031026),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: Color(0xFF2C3A5E)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111A2E),
        hintStyle: const TextStyle(color: Color(0xFFA7B0D3)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF263153)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .6)),
        ),
      ),
      dividerColor: const Color(0xFF263153),
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }

  static TextTheme _textTheme({
    required Color heading,
    required Color body,
    required Color muted,
  }) {
    return TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -.2,
        color: heading,
      ),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: heading),
      titleSmall: TextStyle(fontWeight: FontWeight.w700, color: heading),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, color: heading),
      bodyLarge: TextStyle(color: body, height: 1.4),
      bodyMedium: TextStyle(color: body.withValues(alpha: .9)),
      bodySmall: TextStyle(color: muted),
      labelMedium: TextStyle(color: muted, fontWeight: FontWeight.w600),
    );
  }
}
