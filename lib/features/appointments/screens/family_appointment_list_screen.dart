import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/appointment_card.dart';
import '../widgets/add_note_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';



/// SMAP-23: Family member view of their loved one's upcoming appointments.
///
/// The family member is linked to a caregiver via `linkedCaregiverId` stored
/// in their Firestore user document.  This screen streams *that* caregiver's
/// appointments (read-only — no add / edit / delete actions).
class FamilyAppointmentListScreen extends StatefulWidget {
  const FamilyAppointmentListScreen({super.key});

  @override
  State<FamilyAppointmentListScreen> createState() =>
      _FamilyAppointmentListScreenState();
}

class _FamilyAppointmentListScreenState
    extends State<FamilyAppointmentListScreen> {
  final AppointmentRepository _repository = AppointmentRepository();

  /// Resolves the caregiver ID linked to the current family-member account.
  Future<String?> _resolveLinkedCaregiverId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    // Support both field names for flexibility.
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
              stream:
                  _repository.streamAppointmentsForCaregiver(caregiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load appointments.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  );
                }

                final all = snapshot.data ?? [];
                final now = DateTime.now();

                final upcoming = all
                    .where((a) =>
                        !a.appointmentDateTime.isBefore(now) &&
                        a.status != 'cancelled')
                    .toList();

                final past = all
                    .where((a) =>
                        a.appointmentDateTime.isBefore(now) ||
                        a.status == 'past')
                    .toList();

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    if (all.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildSection(
                              context: context,
                              title: 'Upcoming',
                              count: upcoming.length,
                              countColor: AppColors.purple,
                              appointments: upcoming,
                              isPast: false,
                            ),
                            _buildSection(
                              context: context,
                              title: 'Past',
                              count: past.length,
                              countColor: const Color(0xFF64748B),
                              appointments: past,
                              isPast: true,
                            ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Appointments',
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
              "Your loved one's upcoming & past visits",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required int count,
    required Color countColor,
    required List<AppointmentModel> appointments,
    required bool isPast,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: countColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: countColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (appointments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'No $title appointments.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
          )
        else
          ...appointments.map(
            (a) => AppointmentCard(
              appointment: a,
              // SMAP-24: family can add/edit notes on past appointments
              onAddNote: isPast
                  ? () => _showAddNoteSheet(context, a)
                  : null,
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No appointments yet.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Appointments added by the caregiver will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
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
              'Your account is not yet linked to a caregiver.\nPlease contact support or the caregiver to set this up.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  // ── SMAP-24: Add / edit note bottom sheet ─────────────────────────────────

  void _showAddNoteSheet(BuildContext context, AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddNoteSheet(appointment: appointment),
    );
  }
}
