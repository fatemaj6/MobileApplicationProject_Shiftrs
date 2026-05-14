import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/model/medication_model.dart';
import 'medication_action_menu.dart';
import 'delete_medication_dialog.dart';
/// A card that displays a single medication.
/// Appearance changes based on status: pending / given / missed.
class MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onMarkGiven;
  final VoidCallback onMarkMissed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onMarkGiven,
    required this.onMarkMissed,
    required this.onEdit,
    required this.onDelete,
  });

  // ─── Colour helpers ────────────────────────────────────────────────────────

  Color get _cardBackground {
    switch (medication.status) {
      case 'given':
        return const Color(0xFFDCFCE7); // light green
      case 'missed':
        return const Color(0xFFFEE2E2); // light red
      default:
        return Colors.white; // pending
    }
  }

  Color get _borderColor {
    switch (medication.status) {
      case 'given':
        return const Color(0xFF16A34A);
      case 'missed':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  Color get _statusColor {
    switch (medication.status) {
      case 'given':
        return const Color(0xFF16A34A);
      case 'missed':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  // ─── Status icon ──────────────────────────────────────────────────────────

  Widget _buildStatusIcon() {
    switch (medication.status) {
      case 'given':
        return Icon(Icons.check_circle_outline,
            size: 16, color: _statusColor);
      case 'missed':
        return Icon(Icons.cancel_outlined, size: 16, color: _statusColor);
      default:
        return Icon(Icons.radio_button_unchecked,
            size: 16, color: _statusColor);
    }
  }

  // ─── Last updated ─────────────────────────────────────────────────────────

  String? get _lastUpdated {
    if (medication.updatedAt == null) return null;
    if (medication.status == 'pending') return null;
    final dt = medication.updatedAt!.toDate();
    return DateFormat('h:mm a').format(dt);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            // ── Top row: name + status + menu ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    medication.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: medication.status == 'given'
                          ? const Color(0xFF166534)
                          : medication.status == 'missed'
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                // Status label
                Row(
                  children: [
                    _buildStatusIcon(),
                    const SizedBox(width: 4),
                    Text(
                      medication.status[0].toUpperCase() +
                          medication.status.substring(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
                // Three-dot menu
                MedicationActionMenu(
                  onEdit: onEdit,
                  onDelete: () => _showDeleteDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ── Dosage ──
            Text(
              medication.dosage,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 6),

            // ── Time · Frequency ──
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  medication.time,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF475569)),
                ),
                const SizedBox(width: 6),
                const Text('·',
                    style: TextStyle(color: Color(0xFF94A3B8))),
                const SizedBox(width: 6),
                Text(
                  medication.frequency,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF475569)),
                ),
              ],
            ),

            // ── Instructions ──
            if (medication.instructions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                medication.instructions,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],

            // ── Last updated ──
            if (_lastUpdated != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last updated: $_lastUpdated',
                style: TextStyle(fontSize: 12, color: _statusColor),
              ),
            ],

            // ── Pending action buttons ──
            if (medication.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Mark as Given
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onMarkGiven,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Mark as Given',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Mark as Missed
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMarkMissed,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFFF8FAFC),
                      ),
                      child: const Text(
                        'Mark as Missed',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Delete dialog ────────────────────────────────────────────────────────

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => DeleteMedicationDialog(onConfirm: onDelete),
    );
  }
}