import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../data/model/medication_model.dart';
import '../controllers/medication_controller.dart';
import '../widgets/medication_card.dart';
import 'add_medication_screen.dart';
import 'edit_medication_screen.dart';

/// Main medication screen — shows all medications grouped by status.
/// Uses StreamBuilder so the list updates in real time from Firestore.
class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final MedicationController _controller = MedicationController();

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goToAddMedication(String currentUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(
          patientId: currentUserId,
          caregiverId: currentUserId,
        ),
      ),
    );
  }

  void _goToEditMedication(MedicationModel medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMedicationScreen(medication: medication),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;

    if (currentUserId == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            child: const Text('Back to Login'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: StreamBuilder<List<MedicationModel>>(
          stream: _controller.getMedicationsStream(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final medications = snapshot.data ?? [];

            final pending = medications.where((m) => m.status == 'pending').toList();
            final given = medications.where((m) => m.status == 'given').toList();
            final missed = medications.where((m) => m.status == 'missed').toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medications',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Today's schedule",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => _goToAddMedication(currentUserId),
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              '+ Add New Medication',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0891B2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                if (medications.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSection(
                          title: 'Pending',
                          count: pending.length,
                          countColor: const Color(0xFF64748B),
                          medications: pending,
                        ),
                        _buildSection(
                          title: 'Given',
                          count: given.length,
                          countColor: const Color(0xFF16A34A),
                          medications: given,
                        ),
                        _buildSection(
                          title: 'Missed',
                          count: missed.length,
                          countColor: const Color(0xFFDC2626),
                          medications: missed,
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required int count,
    required Color countColor,
    required List<MedicationModel> medications,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

        if (medications.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'No $title medications.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
          )
        else
          ...medications.map(
            (med) => MedicationCard(
              medication: med,
              onMarkGiven: () async {
                final ok = await _controller.markAsGiven(med.id);
                if (ok) {
                  _showSnackBar('Medication marked as given.');
                }
              },
              onMarkMissed: () async {
                final ok = await _controller.markAsMissed(med.id);
                if (ok) {
                  _showSnackBar('Medication marked as missed.');
                }
              },
              onEdit: () => _goToEditMedication(med),
              onDelete: () async {
                final ok = await _controller.deleteMedication(med.id);
                if (ok) {
                  _showSnackBar('Medication deleted successfully.');
                }
              },
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
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No medications added yet.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap Add New Medication to create one.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}