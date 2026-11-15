import '../material.dart';

/// Colours taken from the Figma design.
abstract final class AppColors {
  static const Color brandBlue = Color(0xFF0E4A91); // splash + auth header
  static const Color brandBlueDark = Color(0xFF0A3A75);
  static const Color primary = Color(0xFF0075FF); // buttons, links, active step
  static const Color mint = Color(0xFF2EE59D); // logo accent
  static const Color teal = Color(0xFF1A9DA3); // summary border, helper text
  static const Color success = Color(0xFF14A05B); // completed steps, checkbox
  static const Color warning = Color(0xFFE59A0C);
  static const Color error = Color(0xFFE5484D);
  static const Color gold = Color(0xFFF5B301);

  static const Color textPrimary = Color(0xFF1B1C1F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFA0A6B1);
  static const Color border = Color(0xFFE1E4EA);
  static const Color divider = Color(0xFFEEF0F3);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color primarySoft = Color(0xFFEAF3FF); // slider track, chips
  static const Color successSoft = Color(0xFFE8F7EF);
  static const Color errorSoft = Color(0xFFFDECEC);
  static const Color warningSoft = Color(0xFFFFF5E1);
  static const Color skeleton = Color(0xFFE6E8EC);

  /// Thin accent along the top edge of the white auth card.
  static const LinearGradient cardAccent = LinearGradient(colors: [Color(0xFF2F80ED), Color(0xFF2BC0A0)]);
}
