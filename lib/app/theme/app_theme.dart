import 'package:flutter/material.dart';

import 'tokens.dart';

/// 应用主题：Material 3 + 自定义 ColorScheme（浅色优先，暗色跟随系统）。
abstract final class OcTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = _scheme(brightness);
    final semantics = isDark ? OcSemantics.dark : OcSemantics.light;
    final textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamilyFallback: ocFontFallback,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      canvasColor: scheme.surface,
      dividerColor: scheme.outlineVariant,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 20),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: OcRadius.cardBorder,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 20),
      primaryIconTheme: IconThemeData(color: scheme.onPrimary, size: 20),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.42),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.8),
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: OcSpace.lg),
          textStyle: textTheme.labelLarge,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: OcRadius.buttonBorder,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline, width: 1),
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: OcSpace.lg),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: OcRadius.buttonBorder,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: OcSpace.md),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: OcRadius.buttonBorder,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainer : scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OcSpace.md,
          vertical: 14,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(color: semantics.danger),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: _inputBorder(scheme.outline),
        enabledBorder: _inputBorder(scheme.outline),
        disabledBorder: _inputBorder(scheme.outlineVariant),
        focusedBorder: _inputBorder(scheme.primary, width: 1.6),
        errorBorder: _inputBorder(semantics.danger),
        focusedErrorBorder: _inputBorder(semantics.danger, width: 1.6),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.outlineVariant,
        thumbColor: scheme.surface,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 9,
          elevation: 2,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        showValueIndicator: ShowValueIndicator.never,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: scheme.outline, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OcRadius.chip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        useIndicator: true,
        minWidth: 72,
        minExtendedWidth: 220,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 22),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 22,
        ),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OcSpace.md,
          vertical: OcSpace.xxs,
        ),
        minVerticalPadding: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OcRadius.button),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(OcSpace.lg),
        shape: RoundedRectangleBorder(
          borderRadius: OcRadius.panelBorder,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : OcColor.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? scheme.onSurface : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(OcSpace.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OcRadius.chip),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : OcColor.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: isDark ? scheme.onSurface : Colors.white,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: OcSpace.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          OcSpace.md,
          0,
          OcSpace.md,
          OcSpace.md,
        ),
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.22),
        selectionHandleColor: scheme.primary,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: OcRadius.inputBorder,
        borderSide: BorderSide(color: color, width: width),
      );

  static ColorScheme _scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return const ColorScheme(
        brightness: Brightness.dark,
        primary: OcColor.darkBrand,
        onPrimary: Color(0xFF1E1B4B),
        primaryContainer: OcColor.darkBrandContainer,
        onPrimaryContainer: OcColor.darkOnBrandContainer,
        secondary: OcColor.darkAccent,
        onSecondary: Color(0xFF042F37),
        secondaryContainer: OcColor.darkAccentContainer,
        onSecondaryContainer: OcColor.darkOnAccentContainer,
        tertiary: OcColor.darkAccent,
        onTertiary: Color(0xFF042F37),
        error: OcColor.darkDanger,
        onError: Color(0xFF450A0A),
        errorContainer: OcColor.darkDangerContainer,
        onErrorContainer: OcColor.darkOnDangerContainer,
        surface: OcColor.darkSurface,
        onSurface: OcColor.darkInk,
        surfaceDim: OcColor.darkBg,
        surfaceBright: OcColor.darkSurfaceRaised,
        surfaceContainerLowest: OcColor.darkBg,
        surfaceContainerLow: Color(0xFF0E1729),
        surfaceContainer: OcColor.darkSurfaceContainer,
        surfaceContainerHigh: OcColor.darkSurfaceRaised,
        surfaceContainerHighest: Color(0xFF223052),
        onSurfaceVariant: OcColor.darkInkSoft,
        outline: OcColor.darkOutline,
        outlineVariant: OcColor.darkLine,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: OcColor.darkInk,
        onInverseSurface: OcColor.darkBg,
        inversePrimary: OcColor.brand,
        surfaceTint: Colors.transparent,
      );
    }
    return const ColorScheme(
      brightness: Brightness.light,
      primary: OcColor.brand,
      onPrimary: Colors.white,
      primaryContainer: OcColor.brandContainer,
      onPrimaryContainer: OcColor.onBrandContainer,
      secondary: OcColor.accent,
      onSecondary: Color(0xFF042F37),
      secondaryContainer: OcColor.accentContainer,
      onSecondaryContainer: OcColor.onAccentContainer,
      tertiary: Color(0xFF0891B2),
      onTertiary: Colors.white,
      error: OcColor.danger,
      onError: Colors.white,
      errorContainer: OcColor.dangerContainer,
      onErrorContainer: OcColor.onDangerContainer,
      surface: OcColor.surface,
      onSurface: OcColor.ink,
      surfaceDim: Color(0xFFDDE5F0),
      surfaceBright: OcColor.surface,
      surfaceContainerLowest: OcColor.bg,
      surfaceContainerLow: Color(0xFFFAFBFD),
      surfaceContainer: OcColor.surfaceSunken,
      surfaceContainerHigh: OcColor.surfaceRaised,
      surfaceContainerHighest: OcColor.line,
      onSurfaceVariant: OcColor.inkSoft,
      outline: OcColor.outline,
      outlineVariant: OcColor.line,
      shadow: Color(0xFF0B1220),
      scrim: Color(0xFF0B1220),
      inverseSurface: OcColor.ink,
      onInverseSurface: Color(0xFFF7F9FC),
      inversePrimary: OcColor.darkBrand,
      surfaceTint: Colors.transparent,
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final ink = scheme.onSurface;
    final soft = scheme.onSurfaceVariant;
    const fallback = ocFontFallback;
    TextStyle style(
      double size,
      FontWeight weight,
      double height, {
      double letterSpacing = 0,
      Color? color,
    }) => TextStyle(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? ink,
      fontFamilyFallback: fallback,
    );

    return TextTheme(
      displayLarge: style(56, FontWeight.w700, 1.08, letterSpacing: -1.6),
      displayMedium: style(44, FontWeight.w700, 1.12, letterSpacing: -1.2),
      displaySmall: style(32, FontWeight.w700, 1.16, letterSpacing: -0.8),
      headlineLarge: style(32, FontWeight.w700, 1.2, letterSpacing: -0.8),
      headlineMedium: style(24, FontWeight.w700, 1.28, letterSpacing: -0.4),
      headlineSmall: style(20, FontWeight.w600, 1.35, letterSpacing: -0.2),
      titleLarge: style(20, FontWeight.w600, 1.4, letterSpacing: -0.2),
      titleMedium: style(16, FontWeight.w600, 1.45),
      titleSmall: style(14, FontWeight.w600, 1.45),
      bodyLarge: style(16, FontWeight.w400, 1.7),
      bodyMedium: style(14, FontWeight.w400, 1.65),
      bodySmall: style(12, FontWeight.w400, 1.6, color: soft),
      labelLarge: style(14, FontWeight.w600, 1.2, letterSpacing: 0.1),
      labelMedium: style(12, FontWeight.w500, 1.2, letterSpacing: 0.1),
      labelSmall: style(12, FontWeight.w500, 1.2, color: soft),
    );
  }
}