import 'package:flutter/material.dart';

/// Three-dot popup menu shown on upcoming appointment cards.
class AppointmentActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AppointmentActionMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(Icons.edit_outlined,
                  size: 18, color: Color(0xFF475569)),
              SizedBox(width: 10),
              Text('Edit Appointment',
                  style: TextStyle(
                      color: Color(0xFF1E293B), fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_outline,
                  size: 18, color: Color(0xFFEF4444)),
              SizedBox(width: 10),
              Text('Delete Appointment',
                  style: TextStyle(
                      color: Color(0xFFEF4444), fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}