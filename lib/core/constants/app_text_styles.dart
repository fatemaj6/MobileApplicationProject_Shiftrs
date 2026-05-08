import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base => GoogleFonts.inter(
    color: AppColors.foreground,
    height: 1.5,
  );

  // Headings
  static TextStyle get h1 => _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get h2 => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get h3 => _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get h4 => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Body
  static TextStyle get bodyLg => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodyMd => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get bodySm => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Secondary text
  static TextStyle get secondary => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get secondarySm => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Muted text
  static TextStyle get muted => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // Label
  static TextStyle get label => _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textLabel,
  );

  // Button
  static TextStyle get button => _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryFg,
  );
}