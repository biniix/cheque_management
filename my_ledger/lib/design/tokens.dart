import 'package:flutter/material.dart';

/// Central design tokens — single source of truth for all visual constants.
/// Keeps radius, shadows, spacing, and animation values consistent across the app.
class DesignTokens {
  DesignTokens._();

  // ── Border Radius ──
  /// Small items: badges, status pills, small containers (6px)
  static const double radiusXs = 6.0;

  /// Button corners, small cards (10px)
  static const double radiusSm = 10.0;

  /// Form fields, dropdowns, input borders (12px)
  static const double radiusMd = 12.0;

  /// Card-style containers, modal items (14px)
  static const double radiusLg = 14.0;

  /// Main card radius — sidebar, content cards, dialogs (18px)
  static const double radiusCard = 18.0;

  /// Hero cards, large containers (20px)
  static const double radiusHero = 20.0;

  /// Bottom sheets, large modals (24px)
  static const double radiusSheet = 24.0;

  // ── Quick shape builders ──
  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get smBorderRadius => BorderRadius.circular(radiusSm);
  static BorderRadius get mdBorderRadius => BorderRadius.circular(radiusMd);

  static RoundedRectangleBorder get cardShape =>
      RoundedRectangleBorder(borderRadius: cardBorderRadius);

  static RoundedRectangleBorder get buttonShape =>
      RoundedRectangleBorder(borderRadius: cardBorderRadius);

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ── Spacing ──
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 20.0;
  static const double spaceXxl = 24.0;
  static const double spaceXxxl = 32.0;

  // ── Edge Insets ──
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceXl);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(spaceXxl);
  static const EdgeInsets formPadding = EdgeInsets.symmetric(
    horizontal: spaceLg,
    vertical: spaceLg,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: spaceXl,
    vertical: spaceLg,
  );

  // ── Animation Durations ──
  static const Duration transitionFast = Duration(milliseconds: 150);
  static const Duration transitionNormal = Duration(milliseconds: 200);
  static const Duration transitionSlow = Duration(milliseconds: 250);

  // ── Sidebar ──
  static const double sidebarWidth = 230.0;
  static const double sidebarRadius = radiusCard;
  static const EdgeInsets sidebarPadding = EdgeInsets.fromLTRB(8, 8, 0, 8);
  static const EdgeInsets sidebarInnerPadding =
      EdgeInsets.fromLTRB(16, 20, 16, 8);
}
