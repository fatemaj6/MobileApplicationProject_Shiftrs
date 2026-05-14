import 'package:flutter/material.dart';

/// A confirmation dialog shown before deleting a medication.
/// Calls [onConfirm] when the user presses "Delete".
class DeleteMedicationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteMedicationDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: const Text(
        'Delete Medication?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xFF1E293B),
        ),
      ),
      content: const Text(
        'Are you sure you want to delete this medication? This action cannot be undone.',
        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            // Cancel button
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Delete button (red)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog first
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}