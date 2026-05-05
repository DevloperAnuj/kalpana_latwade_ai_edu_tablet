import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Light palette ──────────────────────────────────────────────────────────
  static const primary = Color(0xFF2A7AFF);          // Electric Blue
  static const primaryVariant = Color(0xFF6EA8FE);   // Sky Blue
  static const secondary = Color(0xFF10B981);        // Vibrant Mint
  static const secondaryVariant = Color(0xFFA7F3D0); // Pale Mint
  static const tertiary = Color(0xFFF59E0B);         // Sunset Orange
  static const error = Color(0xFFEF4444);            // Watermelon Red

  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBackground = Color(0xFFF0F9FF);  // Soft Breeze
  static const lightOnSurface = Color(0xFF1E293B);   // Deep Charcoal
  static const lightOnSurfaceVariant = Color(0xFF64748B); // Slate Grey
  static const lightOutline = Color(0xFFE2E8F0);     // Light Sky
  static const lightOutlineVariant = Color(0xFFCBD5E1);

  // Containers – light
  static const lightPrimaryContainer = Color(0xFFDBEAFE);  // blue-100
  static const lightOnPrimaryContainer = Color(0xFF1E3A8A);
  static const lightSecondaryContainer = Color(0xFFA7F3D0); // Pale Mint
  static const lightOnSecondaryContainer = Color(0xFF065F46);
  static const lightTertiaryContainer = Color(0xFFFEF3C7);
  static const lightOnTertiaryContainer = Color(0xFF78350F);
  static const lightErrorContainer = Color(0xFFFEE2E2);    // spec quiz wrong bg
  static const lightOnErrorContainer = Color(0xFF7F1D1D);
  static const lightSurfaceContainerHighest = Color(0xFFE2E8F0);
  static const lightSurfaceContainerHigh = Color(0xFFEBF0F7);
  static const lightSurfaceContainer = Color(0xFFF0F5FB);
  static const lightSurfaceContainerLow = Color(0xFFF5FAFF);
  static const lightSurfaceContainerLowest = Color(0xFFFFFFFF);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const darkPrimary = Color(0xFF3B82F6);      // Electric Blue (brighter)
  static const darkSecondary = Color(0xFF10B981);    // Mint (same)

  static const darkSurface = Color(0xFF1E293B);      // Slate
  static const darkBackground = Color(0xFF0F172A);   // Deep Night
  static const darkOnSurface = Color(0xFFF1F5F9);    // Off-white
  static const darkOnSurfaceVariant = Color(0xFF94A3B8); // Light Slate
  static const darkOutline = Color(0xFF334155);
  static const darkOutlineVariant = Color(0xFF475569);

  // Containers – dark
  static const darkPrimaryContainer = Color(0xFF1E3A8A);
  static const darkOnPrimaryContainer = Color(0xFFBFDBFE);
  static const darkSecondaryContainer = Color(0xFF065F46);
  static const darkOnSecondaryContainer = Color(0xFFA7F3D0);
  static const darkTertiaryContainer = Color(0xFF92400E);
  static const darkOnTertiaryContainer = Color(0xFFFDE68A);
  static const darkErrorContainer = Color(0xFF7F1D1D);
  static const darkOnErrorContainer = Color(0xFFFEE2E2);
  static const darkSurfaceContainerHighest = Color(0xFF2D3F55);
  static const darkSurfaceContainerHigh = Color(0xFF253347);
  static const darkSurfaceContainer = Color(0xFF1D2A3C);
  static const darkSurfaceContainerLow = Color(0xFF172233);
  static const darkSurfaceContainerLowest = Color(0xFF0F172A);

  // ── Canvas pattern colours ─────────────────────────────────────────────────
  // Ruled: Soft Slate #94A3B8 at 50% opacity
  static const ruledLineColor = Color(0x8094A3B8);
  // Grid: Soft Teal #99F6E4 at 50% opacity
  static const gridLineColor = Color(0x8099F6E4);
  // Graph minor: Light Mint #A7F3D0 at 50% opacity
  static const graphMinorColor = Color(0x80A7F3D0);
  // Graph major: Vibrant Mint #10B981 at 50% opacity
  static const graphMajorColor = Color(0x8010B981);
}
