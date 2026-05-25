import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import 'appointment_action_menu.dart';
import 'delete_appointment_dialog.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onEdit,
    this.onDelete,
  });

  Color _badgeColor(String type) {
    switch (type) {
      case 'Specialist':
        return const Color(0xFFEDE9FE);
      case 'Lab Test':
        return const Color(0xFFFEF3C7);
      case 'Therapy':
        return const Color(0xFFDCFCE7);
      case 'Follow-up':
        return const Color(0xFFE0F2FE);
      case 'Check-up':
      default:
        return const Color(0xFFEDE9FE);
    }
  }

  Color _badgeTextColor(String type) {
    switch (type) {
      case 'Specialist':
        return const Color(0xFF7C3AED);
      case 'Lab Test':
        return const Color(0xFFD97706);
      case 'Therapy':
        return const Color(0xFF16A34A);
      case 'Follow-up':
        return const Color(0xFF0369A1);
      case 'Check-up':
      default:
        return const Color(0xFF7C3AED);
    }
  }

  bool get _isUpcoming =>
      !appointment.isPast && appointment.status != 'cancelled';

  @override
  Widget build(BuildContext context) {
    final muted = !_isUpcoming;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: muted
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: title + badge + menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    appointment.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: muted
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: muted
                        ? const Color(0xFFE2E8F0)
                        : _badgeColor(appointment.appointmentType),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appointment.appointmentType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: muted
                          ? const Color(0xFF94A3B8)
                          : _badgeTextColor(appointment.appointmentType),
                    ),
                  ),
                ),
                if (_isUpcoming && onEdit != null && onDelete != null)
                  AppointmentActionMenu(
                    onEdit: onEdit!,
                    onDelete: () => _showDeleteDialog(context),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Doctor name
            if (appointment.doctorName.trim().isNotEmpty) ...[
              _infoRow(
                icon: Icons.person_outline,
                label: appointment.doctorName,
                muted: muted,
              ),
              const SizedBox(height: 6),
            ],

            // Specialty
            if (appointment.specialty.trim().isNotEmpty) ...[
              _infoRow(
                icon: Icons.medical_services_outlined,
                label: appointment.specialty,
                muted: muted,
              ),
              const SizedBox(height: 6),
            ],

            _infoRow(
              icon: Icons.calendar_today_outlined,
              label: appointment.formattedDate,
              muted: muted,
            ),
            const SizedBox(height: 6),

            _infoRow(
              icon: Icons.access_time,
              label: appointment.formattedTime,
              muted: muted,
            ),
            const SizedBox(height: 6),

            _infoRow(
              icon: Icons.location_on_outlined,
              label: appointment.clinicName,
              muted: muted,
            ),

            if (appointment.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                appointment.notes,
                style: TextStyle(
                  fontSize: 13,
                  color: muted
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required bool muted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: muted
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF0891B2),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: muted
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => DeleteAppointmentDialog(onConfirm: onDelete!),
    );
  }
}