import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // ← SMAP-31
import '../models/appointment_model.dart';
import '../controllers/appointment_controller.dart';
import '../../../data/services/google_calendar_service.dart';
import 'appointment_action_menu.dart';
import 'delete_appointment_dialog.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddNote;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onEdit,
    this.onDelete,
    this.onAddNote,
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

  Future<void> _syncToGoogleCalendar(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller =
        Provider.of<AppointmentController>(context, listen: false);

    messenger.showSnackBar(
      const SnackBar(content: Text('Syncing to Google Calendar...')),
    );

    final description = appointment.notes.isNotEmpty
        ? appointment.notes
        : '${appointment.specialty} with ${appointment.doctorName}';

    String? eventId;
    if (appointment.googleEventId != null &&
        appointment.googleEventId!.isNotEmpty) {
      eventId = await GoogleCalendarService.updateEvent(
        googleEventId: appointment.googleEventId!,
        title: appointment.title,
        description: description,
        startTime: appointment.appointmentDateTime,
      );
    } else {
      eventId = await GoogleCalendarService.syncAppointment(
        context: context,
        title: appointment.title,
        description: description,
        startTime: appointment.appointmentDateTime,
      );
    }

    if (eventId != null) {
      final updatedAppt = appointment.copyWith(
        googleEventId: eventId,
        googleEventSyncState: 'synced',
      );
      await controller.updateAppointment(updatedAppt);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Synced to Google Calendar'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } else {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('❌ Sync cancelled or failed'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  // ← SMAP-31
  Future<void> _openInMaps(BuildContext context) async {
    final query = appointment.clinicAddress.trim().isNotEmpty
        ? appointment.clinicAddress.trim()
        : appointment.clinicName.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No location available for this appointment.'),
        ),
      );
      return;
    }

    final encoded = Uri.encodeComponent(query);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    }
  }

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
                    onSyncCalendar: () => _syncToGoogleCalendar(context),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            if (appointment.doctorName.trim().isNotEmpty) ...[
              _infoRow(
                icon: Icons.person_outline,
                label: appointment.doctorName,
                muted: muted,
              ),
              const SizedBox(height: 6),
            ],

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

            // ← SMAP-31: tappable location row
            GestureDetector(
              onTap: () => _openInMaps(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: muted
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF0891B2),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.clinicName,
                          style: TextStyle(
                            fontSize: 13,
                            color: muted
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                          ),
                        ),
                        if (!muted &&
                            appointment.clinicAddress.trim().isNotEmpty)
                          Text(
                            appointment.clinicAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        if (!muted)
                          const Text(
                            'Tap to open in Google Maps',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0891B2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!muted)
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Color(0xFF0891B2),
                    ),
                ],
              ),
            ),

            if (appointment.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              if (onAddNote != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: muted
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes,
                        size: 14,
                        color: muted
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF9333EA),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.notes,
                          style: TextStyle(
                            fontSize: 13,
                            color: muted
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF6B21A8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
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

            if (onAddNote != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddNote,
                  icon: Icon(
                    appointment.notes.trim().isNotEmpty
                        ? Icons.edit_note
                        : Icons.note_add_outlined,
                    size: 18,
                    color: const Color(0xFF9333EA),
                  ),
                  label: Text(
                    appointment.notes.trim().isNotEmpty
                        ? 'Edit Note'
                        : 'Add Visit Note',
                    style: const TextStyle(
                      color: Color(0xFF9333EA),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: const BorderSide(color: Color(0xFFD8B4FE)),
                  ),
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
          color: muted ? const Color(0xFFCBD5E1) : const Color(0xFF0891B2),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: muted ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
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