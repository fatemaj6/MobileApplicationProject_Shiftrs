import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../data/model/medication_model.dart';
import '../../../data/services/notification_service.dart';
import '../controllers/medication_controller.dart';

class FamilyMedicationScheduleScreen extends StatefulWidget {
  const FamilyMedicationScheduleScreen({super.key});

  @override
  State<FamilyMedicationScheduleScreen> createState() =>
      _FamilyMedicationScheduleScreenState();
}

class _FamilyMedicationScheduleScreenState
    extends State<FamilyMedicationScheduleScreen> {
  final MedicationController _controller = MedicationController();
  final Set<String> _scheduledIds = {};

  Future<String?> _getLinkedCaregiverId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    return doc.data()?['linkedCaregiverId'];
  }

  DateTime? _parseMedicationTime(String time) {
  try {
    final now = DateTime.now();
    final cleanedTime = time.trim().toUpperCase();

    final parts = cleanedTime.split(' ');
    final hm = parts[0].split(':');

    int hour = int.parse(hm[0]);
    final minute = int.parse(hm[1]);

    if (parts.length > 1) {
      final period = parts[1];

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }
    }

    final scheduledToday = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    return scheduledToday;
  } catch (e) {
    debugPrint('Failed to parse medication time "$time": $e');
    return null;
  }
}

  bool _isMissed(MedicationModel med) {
    if (med.status != 'pending') return false;

    final medTime = _parseMedicationTime(med.time);
    if (medTime == null) return false;

    return DateTime.now().isAfter(
      medTime.add(const Duration(minutes: 30)),
    );
  }

  Future<void> _scheduleReminders(List<MedicationModel> medications) async {
  for (final med in medications) {
    if (med.status != 'pending') continue;
    if (_scheduledIds.contains(med.id)) continue;

    final medTime = _parseMedicationTime(med.time);
    if (medTime == null) continue;

    final reminderTime = medTime.subtract(const Duration(minutes: 1));
    final reminderDelay = reminderTime.difference(DateTime.now());

    if (!reminderDelay.isNegative) {
      Future.delayed(reminderDelay, () {
        NotificationService.showMedicationReminderNow(
          id: med.id.hashCode,
          medicationName: med.name,
        );
      });
    }

    final missedAlertTime = medTime.add(const Duration(minutes: 1));
    final missedDelay = missedAlertTime.difference(DateTime.now());

    if (!missedDelay.isNegative) {
      Future.delayed(missedDelay, () {
        NotificationService.showMissedMedicationNow(
          id: med.id.hashCode + 100000,
          medicationName: med.name,
        );
      });
    }

    _scheduledIds.add(med.id);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: _getLinkedCaregiverId(),
          builder: (context, linkSnapshot) {
            if (linkSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final linkedCaregiverId = linkSnapshot.data;

            if (linkedCaregiverId == null || linkedCaregiverId.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'This family account is not linked to a caregiver yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return StreamBuilder<List<MedicationModel>>(
              stream: _controller.getMedicationsStream(linkedCaregiverId),
              builder: (context, medSnapshot) {
                if (medSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (medSnapshot.hasError) {
                  return Center(child: Text('Error: ${medSnapshot.error}'));
                }

                final medications = medSnapshot.data ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scheduleReminders(medications);
                });

                final given =
                    medications.where((m) => m.status == 'given').toList();

                final pending =
                    medications.where((m) => m.status == 'pending').toList();

                final missed =
                    medications.where((m) => m.status == 'missed').toList();

                final totalCount = medications.length;
                final adherence = totalCount == 0
                    ? 0
                    : ((given.length / totalCount) * 100).round();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _Header(onBack: () => Navigator.pop(context)),
                    const SizedBox(height: 18),
                    _AdherenceCard(
                      adherence: adherence,
                      givenCount: given.length,
                      totalCount: totalCount,
                    ),
                    const SizedBox(height: 16),
                    _OverviewCard(
                      givenCount: given.length,
                      pendingCount: pending.length,
                      missedCount: missed.length,
                    ),
                    const SizedBox(height: 18),
                    if (medications.isEmpty)
                      const _EmptyState()
                    else ...[
                      _MedicationSection(
                        title: 'Given',
                        count: given.length,
                        medications: given,
                        statusColor: const Color(0xFF16A34A),
                        backgroundColor: const Color(0xFFF0FDF4),
                        borderColor: const Color(0xFFBBF7D0),
                      ),
                      _MedicationSection(
                        title: 'Pending',
                        count: pending.length,
                        medications: pending,
                        statusColor: const Color(0xFF64748B),
                        backgroundColor: Colors.white,
                        borderColor: const Color(0xFFE2E8F0),
                      ),
                      _MedicationSection(
                        title: 'Missed',
                        count: missed.length,
                        medications: missed,
                        statusColor: const Color(0xFFDC2626),
                        backgroundColor: const Color(0xFFFEF2F2),
                        borderColor: const Color(0xFFFECACA),
                        showMissedAlert: true,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 6),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 3),
            Text(
              "Today's medication status",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdherenceCard extends StatelessWidget {
  final int adherence;
  final int givenCount;
  final int totalCount;

  const _AdherenceCard({
    required this.adherence,
    required this.givenCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Adherence Rate",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$adherence%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$givenCount of $totalCount taken',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final int givenCount;
  final int pendingCount;
  final int missedCount;

  const _OverviewCard({
    required this.givenCount,
    required this.pendingCount,
    required this.missedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _OverviewItem(
                count: givenCount,
                label: 'Given',
                color: const Color(0xFF16A34A),
                bg: const Color(0xFFDCFCE7),
              ),
              _OverviewItem(
                count: pendingCount,
                label: 'Pending',
                color: const Color(0xFF64748B),
                bg: const Color(0xFFF1F5F9),
              ),
              _OverviewItem(
                count: missedCount,
                label: 'Missed',
                color: const Color(0xFFDC2626),
                bg: const Color(0xFFFEE2E2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color bg;

  const _OverviewItem({
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: bg,
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationSection extends StatelessWidget {
  final String title;
  final int count;
  final List<MedicationModel> medications;
  final Color statusColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool showMissedAlert;

  const _MedicationSection({
    required this.title,
    required this.count,
    required this.medications,
    required this.statusColor,
    required this.backgroundColor,
    required this.borderColor,
    this.showMissedAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 10,
                backgroundColor: statusColor.withOpacity(0.13),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...medications.map(
            (med) => _MedicationTile(
              medication: med,
              statusColor: statusColor,
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              showMissedAlert: showMissedAlert,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  final MedicationModel medication;
  final Color statusColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool showMissedAlert;

  const _MedicationTile({
    required this.medication,
    required this.statusColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.showMissedAlert,
  });

  String get _statusLabel {
    if (showMissedAlert) return 'Missed';
    if (medication.status == 'given') return 'Given';
    return 'Pending';
  }

  IconData get _statusIcon {
    if (showMissedAlert) return Icons.cancel_outlined;
    if (medication.status == 'given') return Icons.check_circle_outline;
    return Icons.radio_button_unchecked;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medication.name,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(_statusIcon, color: statusColor, size: 17),
              const SizedBox(width: 4),
              Text(
                _statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            medication.dosage,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 15, color: statusColor),
              const SizedBox(width: 5),
              Text(
                medication.time,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '• ${medication.frequency}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (medication.instructions.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              medication.instructions,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
          if (showMissedAlert) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This medication may have been missed.',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 52,
            color: Color(0xFFCBD5E1),
          ),
          SizedBox(height: 12),
          Text(
            'No medication schedule available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}