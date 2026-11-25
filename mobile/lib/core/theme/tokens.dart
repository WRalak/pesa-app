import 'package:material_ui/material_ui.dart';

/// Pesa design tokens. Deep navy anchors trust; emerald signals money that is
/// "good to go"; warm gold is reserved for rewards and highlights.
abstract final class PesaColors {
  static const navy950 = Color(0xFF06111C);
  static const navy900 = Color(0xFF0B1B2B);
  static const navy800 = Color(0xFF12283D);
  static const navy700 = Color(0xFF1C3A55);
  static const emerald600 = Color(0xFF059669);
  static const emerald500 = Color(0xFF10B981);
  static const emerald100 = Color(0xFFD1FAE5);
  static const gold500 = Color(0xFFF5B841);
  static const coral500 = Color(0xFFEF6F5E);
  static const sky500 = Color(0xFF3B82F6);
  static const violet500 = Color(0xFF8B5CF6);

  static const bgLight = Color(0xFFF6F7F9);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFF1F4F7);
  static const borderLight = Color(0xFFE3E8EE);
  static const textLight = Color(0xFF0B1B2B);
  static const text2Light = Color(0xFF4A5B6D);
  static const text3Light = Color(0xFF8494A5);

  static const bgDark = Color(0xFF07121D);
  static const surfaceDark = Color(0xFF0E1E2E);
  static const surface2Dark = Color(0xFF132739);
  static const borderDark = Color(0xFF1F364C);
  static const textDark = Color(0xFFE8EEF4);
  static const text2Dark = Color(0xFFA9B8C7);
  static const text3Dark = Color(0xFF6F8296);

  static const success = Color(0xFF047857);
  static const warning = Color(0xFFB7791F);
  static const danger = Color(0xFFDC3B2E);

  /// Category palette for charts — distinguishable in light and dark.
  static const chart = [emerald500, sky500, gold500, violet500, coral500, Color(0xFF14B8A6), Color(0xFFEC4899), Color(0xFF64748B)];
}

abstract final class Space {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24, xxxl = 32;
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: 20);
}

abstract final class Radii {
  static const double sm = 10, md = 14, lg = 20, xl = 28;
  static BorderRadius get card => BorderRadius.circular(lg);
}
