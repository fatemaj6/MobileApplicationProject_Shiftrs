import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../appointments/models/appointment_model.dart';
import '../../appointments/repositories/appointment_repository.dart';

class AppointmentNotificationBell extends StatelessWidget {
  final VoidCallback onTap;

  const AppointmentNotificationBell({super.key, required this.onTap});

  Future<String?> _linkedCaregiverId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return (data['linkedCaregiverId'] ?? data['caregiverId']) as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _linkedCaregiverId(),
      builder: (context, caregiverSnap) {
        final caregiverId = caregiverSnap.data;

        if (caregiverId == null || caregiverId.isEmpty) {
          return _BellButton(count: 0, onTap: onTap);
        }

        return FutureBuilder<List<AppointmentModel>>(
          //no need for stream, just update on home screen load
          future: AppointmentRepository().getAppointmentsForCaregiver(
            caregiverId,
          ),
          builder: (context, snapshot) {
            final now = DateTime.now();
            final soonCutoff = now.add(const Duration(days: 7));

            final soonCount = (snapshot.data ?? [])
                .where(
                  (a) =>
                      !a.appointmentDateTime.isBefore(now) &&
                      !a.appointmentDateTime.isAfter(soonCutoff) &&
                      a.status != 'cancelled',
                )
                .length;

            return _BellButton(count: soonCount, onTap: onTap);
          },
        );
      },
    );
  }
}

class _BellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _BellButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none,
              color: Color(0xFF1E293B),
              size: 26,
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
