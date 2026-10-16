import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Palette ──────────────────────────────
  static const Color primary        = Color(0xFF3730A3); // Deep Indigo
  static const Color primaryLight   = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark    = Color(0xFF1E1B6E); // Indigo 900

  // ── Accent / Secondary ───────────────────────────
  static const Color accent         = Color(0xFF7C3AED); // Radiant Violet
  static const Color accentLight    = Color(0xFFA78BFA); // Violet 400
  static const Color accentDark     = Color(0xFF5B21B6); // Violet 700

  // ── Semantic Colors ──────────────────────────────
  static const Color success        = Color(0xFF059669); // Emerald
  static const Color warning        = Color(0xFFD97706); // Amber
  static const Color error          = Color(0xFFDC2626); // Red
  static const Color info           = Color(0xFF0284C7); // Sky

  // ── Light Mode Surfaces ──────────────────────────
  static const Color background     = Color(0xFFF8F9FC); // Soft Slate bg
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color borderLight    = Color(0xFFE2E8F0);
  static const Color textPrimary    = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary  = Color(0xFF64748B); // Slate 500

  // ── Dark Mode Surfaces ───────────────────────────
  static const Color backgroundDark = Color(0xFF0F0F1A); // Rich dark
  static const Color surfaceDark    = Color(0xFF1A1A2E); // Card dark
  static const Color cardDark       = Color(0xFF16213E);
  static const Color borderDark     = Color(0xFF2D2D4E);
  static const Color textPrimaryDk  = Color(0xFFF1F5F9);
  static const Color textSecondaryDk= Color(0xFF94A3B8);

  // ── Gradient Presets ─────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF3730A3), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}