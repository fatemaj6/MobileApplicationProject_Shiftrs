import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../appointments/models/appointment_model.dart';
import '../../appointments/repositories/appointment_repository.dart';

import '../../../../core/routes/app_routes.dart'; //for redirecting back to appointment list screen

class AppointmentNotificationsScreen extends StatelessWidget {
  const AppointmentNotificationsScreen({super.key});

  Future<String?> _resolveLinkedCaregiverId() async {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _resolveLinkedCaregiverId(),
          builder: (context, caregiverSnap) {
            if (caregiverSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final caregiverId = caregiverSnap.data;

            if (caregiverId == null || caregiverId.isEmpty) {
              return _buildNotLinked(context);
            }

            return StreamBuilder<List<AppointmentModel>>(
              stream: AppointmentRepository().streamAppointmentsForCaregiver(
                caregiverId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final now = DateTime.now();
                final soonCutoff = now.add(const Duration(days: 7));

                final upcoming =
                    (snapshot.data ?? [])
                        .where(
                          (a) =>
                              !a.appointmentDateTime.isBefore(now) &&
                              a.status != 'cancelled',
                        )
                        .toList()
                      ..sort(
                        (a, b) => a.appointmentDateTime.compareTo(
                          b.appointmentDateTime,
                        ),
                      );

                final soon = upcoming
                    .where((a) => !a.appointmentDateTime.isAfter(soonCutoff))
                    .toList();

                final later = upcoming
                    .where((a) => a.appointmentDateTime.isAfter(soonCutoff))
                    .toList();

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    if (upcoming.isEmpty)
                      SliverFillRemaining(child: _buildEmpty())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (soon.isNotEmpty) ...[
                              _sectionTitle(
                                'Coming Soon',
                                Icons.notification_important_outlined,
                                const Color(0xFFEF4444),
                              ),
                              const SizedBox(height: 8),
                              ...soon.map(
                                (a) => _NotificationTile(
                                  appointment: a,
                                  isSoon: true,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (later.isNotEmpty) ...[
                              _sectionTitle(
                                'Upcoming',
                                Icons.calendar_month_outlined,
                                const Color(0xFF9333EA),
                              ),
                              const SizedBox(height: 8),
                              ...later.map(
                                (a) => _NotificationTile(
                                  appointment: a,
                                  isSoon: false,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                          ]),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 52),
            child: Text(
              'Upcoming appointment reminders',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No upcoming appointments.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You'll be notified when new appointments are scheduled.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLinked(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No linked caregiver',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Link your account to a caregiver to receive appointment notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isSoon;

  const _NotificationTile({required this.appointment, required this.isSoon});

  String get _daysUntil {
    final diff = appointment.appointmentDateTime
        .difference(DateTime.now())
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = isSoon
        ? const Color(0xFFEF4444)
        : const Color(0xFF9333EA);
    final bgColor = isSoon ? const Color(0xFFFEF2F2) : const Color(0xFFF3E8FF);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.familyAppointments),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSoon ? const Color(0xFFFECACA) : const Color(0xFFE9D5FF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 58,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      appointment.dayNumber,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      appointment.shortMonth.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appointment.clinicName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appointment.formattedTime,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _daysUntil,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
