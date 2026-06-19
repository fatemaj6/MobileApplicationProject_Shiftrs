import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/model/health_alert_model.dart';
import '../../../data/repositories/health_alert_repository.dart';

class HealthAlertsScreen extends StatelessWidget {
  final String caregiverId;
  final bool isFamilyView;

  const HealthAlertsScreen({
    super.key,
    required this.caregiverId,
    this.isFamilyView = false,
  });

  @override
  Widget build(BuildContext context) {
    final repository = HealthAlertRepository();
    final activeColor = isFamilyView ? AppColors.purple : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isFamilyView ? 'Emergency Alerts' : 'Health Alerts'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
      ),
      body: StreamBuilder<List<HealthAlertModel>>(
        stream: repository.streamAlertsForCaregiver(caregiverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return _EmptyAlertsState(
              activeColor: activeColor,
              activeBg: isFamilyView ? AppColors.purpleBg : AppColors.cyanBg,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _HealthAlertCard(
                alert: alerts[index],
                isFamilyView: isFamilyView,
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyAlertsState extends StatelessWidget {
  final Color activeColor;
  final Color activeBg;

  const _EmptyAlertsState({required this.activeColor, required this.activeBg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: activeBg,
              child: Icon(
                Icons.verified_outlined,
                color: activeColor,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No health alerts right now',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No abnormal health patterns were detected from care notes, medications, or appointments.',
              style: AppTextStyles.secondarySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthAlertCard extends StatelessWidget {
  final HealthAlertModel alert;
  final bool isFamilyView;

  const _HealthAlertCard({required this.alert, required this.isFamilyView});

  Color get _typeColor {
    switch (alert.type) {
      case 'blood_pressure':
        return AppColors.vitalsColor;
      case 'mood_pattern':
        return AppColors.moodColor;
      case 'sleep_low':
        return AppColors.primary;
      case 'symptom_keyword':
        return AppColors.symptomsColor;
      case 'missed_medication':
        return AppColors.missed;
      case 'appointment_load':
        return AppColors.purple;
      default:
        return AppColors.generalColor;
    }
  }

  Color get _typeBg {
    switch (alert.type) {
      case 'blood_pressure':
        return AppColors.vitalsBg;
      case 'mood_pattern':
        return AppColors.moodBg;
      case 'sleep_low':
        return AppColors.cyanBg;
      case 'symptom_keyword':
        return AppColors.symptomsBg;
      case 'missed_medication':
        return AppColors.missedBg;
      case 'appointment_load':
        return AppColors.purpleBg;
      default:
        return AppColors.generalBg;
    }
  }

  String get _categoryLabel {
    switch (alert.type) {
      case 'blood_pressure':
        return 'Vitals';
      case 'mood_pattern':
        return 'Mood';
      case 'sleep_low':
        return 'Sleep';
      case 'symptom_keyword':
        return 'Symptoms';
      case 'missed_medication':
        return 'Medication';
      case 'appointment_load':
        return 'Appointments';
      default:
        return 'General';
    }
  }

  IconData get _icon {
    switch (alert.type) {
      case 'blood_pressure':
        return Icons.monitor_heart_outlined;
      case 'mood_pattern':
        return Icons.mood_bad_outlined;
      case 'sleep_low':
        return Icons.bedtime_outlined;
      case 'symptom_keyword':
        return Icons.warning_amber_rounded;
      case 'missed_medication':
        return Icons.medication_outlined;
      case 'appointment_load':
        return Icons.calendar_month_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }

  Color get _severityColor {
    switch (alert.severity) {
      case 'high':
        return AppColors.destructive;
      case 'medium':
        return AppColors.alertAmber;
      default:
        return AppColors.primary;
    }
  }

  String get _suggestedAction {
    switch (alert.type) {
      case 'blood_pressure':
        return alert.severity == 'high'
            ? 'Contact the caregiver and seek urgent medical advice if symptoms are present.'
            : 'Ask the caregiver to recheck blood pressure and keep monitoring.';
      case 'mood_pattern':
        return 'Check in with the patient and review recent care notes with the caregiver.';
      case 'sleep_low':
        return 'Encourage rest and ask the caregiver to monitor sleep again tonight.';
      case 'symptom_keyword':
        return 'Review the care note details and contact the caregiver for context.';
      case 'missed_medication':
        return 'Confirm the medication schedule with the caregiver.';
      case 'appointment_load':
        return 'Review upcoming appointments and help with transport or reminders.';
      default:
        return 'Review the patient status and contact the caregiver if needed.';
    }
  }

  String _dateTimeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final createdDate = alert.createdAt?.toDate();
    final borderColor = alert.severity == 'high'
        ? AppColors.destructive.withOpacity(0.38)
        : _typeColor.withOpacity(0.22);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _typeBg,
            child: Icon(_icon, color: _typeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isFamilyView && alert.severity == 'high'
                              ? AppColors.destructive
                              : AppColors.foreground,
                        ),
                      ),
                    ),
                    _CategoryChip(
                      label: _categoryLabel,
                      color: _typeColor,
                      bgColor: _typeBg,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(alert.message, style: AppTextStyles.secondarySm),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallChip(
                      label: alert.severity.toUpperCase(),
                      color: _severityColor,
                    ),
                    _SmallChip(
                      label: alert.source.replaceAll('_', ' '),
                      color: AppColors.textMuted,
                    ),
                    if (createdDate != null)
                      _SmallChip(
                        label: _dateTimeLabel(createdDate),
                        color: AppColors.textMuted,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFamilyView
                        ? AppColors.purpleBg.withOpacity(0.55)
                        : AppColors.cyanBg.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested action',
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isFamilyView
                              ? AppColors.purple
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(_suggestedAction, style: AppTextStyles.secondarySm),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _CategoryChip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
