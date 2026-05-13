import 'package:flutter/material.dart';

/// The three-dot popup menu shown on every medication card.
/// Provides "Edit Medication" and "Delete Medication" options.
class MedicationActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationActionMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        // Edit option
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
              SizedBox(width: 10),
              Text(
                'Edit Medication',
                style: TextStyle(color: Color(0xFF1E293B), fontSize: 14),
              ),
            ],
          ),
        ),
        // Delete option (red)
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text(
                'Delete Medication',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}