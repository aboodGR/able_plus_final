import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AbleColors {
  static const lightPrimary = Color(0xFF0B82D2);
  static const lightPrimaryDark = Color(0xFF096FB3);
  static const lightSecondary = Color(0xFF0992C2);
  static const lightAccent = Color(0xFF0AC4E0);
  static const lightBackground = Color(0xFFF3F8FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF8FBFD);
  static const lightGlass = Color(0xFFFDFEFE);
  static const lightBorder = Color(0xFFDDEBF3);
  static const lightText = Color(0xFF324F73);
  static const lightTextMuted = Color(0xFF8EA2BD);

  static const darkPrimary = Color(0xFF0B82D2);
  static const darkPrimaryDark = Color(0xFF096FB3);
  static const darkSecondary = Color(0xFF0AC4E0);
  static const darkBackground = Color(0xFF121A26);
  static const darkSurface = Color(0xFF182437);
  static const darkCard = Color(0xFF1A2740);
  static const darkGlass = Color(0xFF1A2740);
  static const darkBorder = Color(0xFF253552);
  static const darkText = Color(0xFFEAF4F7);
  static const darkTextMuted = Color(0xFF8DA2C0);

  static const success = Color(0xFF49B87D);
  static const warning = Color(0xFFF0B156);
  static const danger = Color(0xFFE16D7A);
}

class AbleAssets {
  static const bgLight = 'assets/images/bg_light.png';
  static const bgDark = 'assets/images/bg_dark.png';
  static const logo = 'assets/images/logo.png';
}

class AbleTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AbleColors.lightPrimary,
      onPrimary: Colors.white,
      secondary: AbleColors.lightSecondary,
      onSecondary: Colors.white,
      error: AbleColors.danger,
      onError: Colors.white,
      surface: AbleColors.lightSurface,
      onSurface: AbleColors.lightText,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AbleColors.lightText,
        displayColor: AbleColors.lightText,
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AbleColors.lightText,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AbleColors.lightText,
        ),
        iconTheme: const IconThemeData(
          color: AbleColors.lightText,
          size: 22,
        ),
      ),
      dividerColor: AbleColors.lightBorder,
      cardColor: Colors.white.withOpacity(0.72),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.72),
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x220AC4E0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.55), width: 1),
        ),
      ),
      inputDecorationTheme: _inputTheme(base, isDark: false),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AbleColors.lightPrimary,
          disabledBackgroundColor: AbleColors.lightPrimary.withOpacity(0.35),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AbleColors.lightPrimaryDark,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: Colors.white.withOpacity(0.58)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AbleColors.lightPrimaryDark,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AbleColors.lightPrimaryDark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AbleColors.lightPrimary,
        unselectedItemColor: AbleColors.lightTextMuted,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFEAF7FC),
        side: BorderSide(color: Colors.white.withOpacity(0.50)),
        labelStyle: GoogleFonts.poppins(
          color: AbleColors.lightPrimaryDark,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AbleColors.lightText,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AbleColors.lightPrimary,
      ),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AbleColors.darkPrimary,
      onPrimary: Colors.white,
      secondary: AbleColors.darkSecondary,
      onSecondary: Colors.white,
      error: AbleColors.danger,
      onError: Colors.white,
      surface: AbleColors.darkSurface,
      onSurface: AbleColors.darkText,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AbleColors.darkText,
        displayColor: AbleColors.darkText,
      ),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AbleColors.darkText,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AbleColors.darkText,
        ),
        iconTheme: const IconThemeData(
          color: AbleColors.darkText,
          size: 22,
        ),
      ),
      dividerColor: AbleColors.darkBorder,
      cardColor: Colors.white.withOpacity(0.06),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.06),
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x66000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
        ),
      ),
      inputDecorationTheme: _inputTheme(base, isDark: true),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AbleColors.darkPrimary,
          disabledBackgroundColor: AbleColors.darkPrimary.withOpacity(0.35),
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AbleColors.darkText,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AbleColors.darkSecondary,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AbleColors.darkText),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AbleColors.darkSecondary,
        unselectedItemColor: AbleColors.darkTextMuted,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFF162133),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
        labelStyle: GoogleFonts.poppins(
          color: AbleColors.darkSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A2740),
        contentTextStyle: GoogleFonts.poppins(color: AbleColors.darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AbleColors.darkSecondary,
      ),
    );
  }

  static InputDecorationTheme _inputTheme(ThemeData base, {required bool isDark}) {
    final muted = isDark ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;
    final fill = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.68);
    final border = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.60);
    final focus = isDark ? AbleColors.darkPrimary : AbleColors.lightPrimary;

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      hintStyle: GoogleFonts.poppins(color: muted, fontSize: 13, fontWeight: FontWeight.w400),
      labelStyle: GoogleFonts.poppins(color: muted, fontSize: 13),
      prefixIconColor: muted,
      suffixIconColor: muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: focus, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AbleColors.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AbleColors.danger, width: 1.4),
      ),
    );
  }

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static String backgroundAsset(BuildContext context) => isDark(context) ? AbleAssets.bgDark : AbleAssets.bgLight;
  static String get logoAsset => AbleAssets.logo;

  static Color textPrimary(BuildContext context) => isDark(context) ? AbleColors.darkText : AbleColors.lightText;
  static Color textMuted(BuildContext context) => isDark(context) ? AbleColors.darkTextMuted : AbleColors.lightTextMuted;
  static Color accent(BuildContext context) => isDark(context) ? AbleColors.darkSecondary : AbleColors.lightPrimaryDark;
  static Color primary(BuildContext context) => isDark(context) ? AbleColors.darkPrimary : AbleColors.lightPrimary;
  static Color glassCard(BuildContext context) => isDark(context) ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.72);
  static Color glassBorder(BuildContext context) => isDark(context) ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55);
  static Color panelFill(BuildContext context) => isDark(context) ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F8FC).withOpacity(0.85);
  static Color iconBubble(BuildContext context) => isDark(context) ? Colors.white.withOpacity(0.08) : const Color(0xFFE8F7FC);
  static Color screenOverlay(BuildContext context) => isDark(context) ? Colors.black.withOpacity(0.10) : Colors.white.withOpacity(0.03);

  static LinearGradient actionGradient(BuildContext context) {
    if (isDark(context)) {
      return const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF0B2C66), Color(0xFF1551A8), Color(0xFF6ED4E6)],
      );
    }
    return const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF0B82D2), Color(0xFF45AEDD), Color(0xFF7BD8E8)],
    );
  }
}
