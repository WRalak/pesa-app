import 'package:material_ui/material_ui.dart';
import 'tokens.dart';

/// Brand-specific semantic colours not covered by [ColorScheme].
@immutable
class PesaPalette extends ThemeExtension<PesaPalette> {
  const PesaPalette({required this.text2, required this.text3, required this.surface2, required this.border, required this.success, required this.warning, required this.heroGradient});
  final Color text2, text3, surface2, border, success, warning;
  final List<Color> heroGradient;

  @override
  PesaPalette copyWith({Color? text2, Color? text3, Color? surface2, Color? border, Color? success, Color? warning, List<Color>? heroGradient}) =>
      PesaPalette(text2: text2 ?? this.text2, text3: text3 ?? this.text3, surface2: surface2 ?? this.surface2, border: border ?? this.border, success: success ?? this.success, warning: warning ?? this.warning, heroGradient: heroGradient ?? this.heroGradient);

  @override
  PesaPalette lerp(ThemeExtension<PesaPalette>? other, double t) => this;
}

extension PesaThemeX on BuildContext {
  PesaPalette get palette => Theme.of(this).extension<PesaPalette>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

class PesaTheme {
  static const _font = 'Satoshi';
  static const _fallback = ['Roboto', 'SF Pro Text', 'Helvetica Neue', 'sans-serif'];

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: PesaColors.emerald600,
      onPrimary: Colors.white,
      primaryContainer: dark ? const Color(0xFF0E2E24) : PesaColors.emerald100,
      onPrimaryContainer: dark ? PesaColors.emerald100 : PesaColors.navy900,
      secondary: PesaColors.navy900,
      onSecondary: Colors.white,
      tertiary: PesaColors.gold500,
      onTertiary: PesaColors.navy900,
      error: PesaColors.danger,
      onError: Colors.white,
      surface: dark ? PesaColors.surfaceDark : PesaColors.surfaceLight,
      onSurface: dark ? PesaColors.textDark : PesaColors.textLight,
      surfaceContainerLowest: dark ? PesaColors.bgDark : PesaColors.bgLight,
      surfaceContainerHighest: dark ? PesaColors.surface2Dark : PesaColors.surface2Light,
      outline: dark ? PesaColors.borderDark : PesaColors.borderLight,
      outlineVariant: dark ? PesaColors.borderDark : PesaColors.borderLight,
    );
    final palette = PesaPalette(
      text2: dark ? PesaColors.text2Dark : PesaColors.text2Light,
      text3: dark ? PesaColors.text3Dark : PesaColors.text3Light,
      surface2: dark ? PesaColors.surface2Dark : PesaColors.surface2Light,
      border: dark ? PesaColors.borderDark : PesaColors.borderLight,
      success: dark ? PesaColors.emerald500 : PesaColors.success,
      warning: dark ? PesaColors.gold500 : PesaColors.warning,
      heroGradient: const [PesaColors.navy900, PesaColors.navy700],
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b, fontFamily: _font, fontFamilyFallback: _fallback);
    final t = base.textTheme;
    final textTheme = t.copyWith(
      displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1, height: 1.1),
      headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: t.bodyMedium?.copyWith(height: 1.45),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      textTheme: textTheme,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: Radii.card, side: BorderSide(color: palette.border)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: palette.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide(color: palette.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: const BorderSide(color: PesaColors.emerald500, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: const BorderSide(color: PesaColors.danger)),
        labelStyle: TextStyle(color: palette.text2),
        hintStyle: TextStyle(color: palette.text3),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: palette.border)),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md))),
    );
  }
}
