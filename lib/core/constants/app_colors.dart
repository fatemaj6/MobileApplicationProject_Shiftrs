import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — cyan
  static const Color primary        = Color(0xFF0891B2); // cyan-600
  static const Color primaryLight   = Color(0xFF06B6D4); // cyan-500
  static const Color primaryFg      = Color(0xFFFFFFFF);
  static const Color primaryHover   = Color(0xFF0E7490); // cyan-700

  // Purple — family role + AI
  static const Color purple         = Color(0xFF9333EA); // purple-600
  static const Color purpleLight    = Color(0xFFA855F7); // purple-500
  static const Color purpleBg       = Color(0xFFF3E8FF); // purple-100
  static const Color purpleHover    = Color(0xFF7E22CE); // purple-700

  // Background & Surface
  static const Color background     = Color(0xFFF9FAFB); // gray-50
  static const Color card           = Color(0xFFFFFFFF);
  static const Color border         = Color(0xFFE5E7EB); // gray-200
  static const Color borderLight    = Color(0xFFF3F4F6); // gray-100

  // Text
  static const Color foreground     = Color(0xFF111827); // gray-900
  static const Color textSecondary  = Color(0xFF6B7280); // gray-500
  static const Color textMuted      = Color(0xFF9CA3AF); // gray-400
  static const Color textLabel      = Color(0xFF374151); // gray-700

  // Medication status
  static const Color given          = Color(0xFF16A34A); // green-600
  static const Color givenBg        = Color(0xFFF0FDF4); // green-50
  static const Color givenBorder    = Color(0xFFBBF7D0); // green-200
  static const Color givenText      = Color(0xFF166534); // green-800

  static const Color missed         = Color(0xFFDC2626); // red-600
  static const Color missedBg       = Color(0xFFFEF2F2); // red-50
  static const Color missedBorder   = Color(0xFFFECACA); // red-200
  static const Color missedText     = Color(0xFF991B1B); // red-800

  static const Color pending        = Color(0xFF6B7280); // gray-500
  static const Color pendingBg      = Color(0xFFF9FAFB); // gray-50
  static const Color pendingBorder  = Color(0xFFE5E7EB); // gray-200
  static const Color pendingText    = Color(0xFF1F2937); // gray-800

  // Notification types
  static const Color alertAmber     = Color(0xFFD97706); // amber-600
  static const Color alertAmberBg   = Color(0xFFFFFBEB); // amber-50
  static const Color alertAmberBorder = Color(0xFFFDE68A); // amber-200

  // Category colors — care notes
  static const Color vitalsColor    = Color(0xFFDC2626); // red-600
  static const Color vitalsBg       = Color(0xFFFEF2F2); // red-50
  static const Color moodColor      = Color(0xFFCA8A04); // yellow-600
  static const Color moodBg         = Color(0xFFFEFCE8); // yellow-50
  static const Color mealsColor     = Color(0xFFEA580C); // orange-600
  static const Color mealsBg        = Color(0xFFFFF7ED); // orange-50
  static const Color activitiesColor = Color(0xFFDB2777); // pink-600
  static const Color activitiesBg   = Color(0xFFFDF2F8); // pink-50
  static const Color symptomsColor  = Color(0xFF9333EA); // purple-600
  static const Color symptomsBg     = Color(0xFFF3E8FF); // purple-50
  static const Color generalColor   = Color(0xFF6B7280); // gray-600
  static const Color generalBg      = Color(0xFFF9FAFB); // gray-50

  // Appointment type colors
  static const Color checkupBg      = Color(0xFFEFF6FF); // blue-50
  static const Color checkupText    = Color(0xFF1D4ED8); // blue-700
  static const Color specialistBg   = Color(0xFFF3E8FF); // purple-100
  static const Color specialistText = Color(0xFF7E22CE); // purple-700
  static const Color therapyBg      = Color(0xFFF0FDFA); // teal-50
  static const Color therapyText    = Color(0xFF0F766E); // teal-700
  static const Color labBg          = Color(0xFFFFFBEB); // amber-50
  static const Color labText        = Color(0xFFB45309); // amber-700

  // Misc
  static const Color green          = Color(0xFF16A34A);
  static const Color greenBg        = Color(0xFFF0FDF4);
  static const Color destructive    = Color(0xFFEF4444);
  static const Color cyanBg         = Color(0xFFECFEFF); // cyan-50
  static const Color cyanLight      = Color(0xFFCFFAFE); // cyan-100
  static const Color inputBg        = Color(0xFFFFFFFF);
}