import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/care_note_controller.dart';
import '../models/care_note_model.dart';
import 'add_care_note_screen.dart';
import 'edit_care_note_screen.dart';

class CareNoteListScreen extends StatefulWidget {
  const CareNoteListScreen({super.key});

  @override
  State<CareNoteListScreen> createState() => _CareNoteListScreenState();
}

class _CareNoteListScreenState extends State<CareNoteListScreen> {
  final CareNoteController _controller = CareNoteController();

  void _goToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCareNoteScreen()),
    );
  }

  void _goToEdit(CareNoteModel note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditCareNoteScreen(note: note)),
    );
  }

  Future<void> _delete(CareNoteModel note) async {
    final ok = await _controller.deleteCareNote(note.id);
    if (!mounted) return;
    _showSnackBar(
      ok
          ? 'Care note deleted.'
          : (_controller.errorMessage ?? 'Delete failed.'),
      isError: !ok,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.destructive : AppColors.given,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<CareNoteModel>>(
          stream: _controller.streamCareNotes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final notes = snapshot.data ?? [];

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text(
                                'Care Notes',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.foreground,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 52),
                          child: Text(
                            'Daily record of meals, mood, vitals and sleep',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _goToAdd,
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                            label: const Text(
                              'Add Care Note',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
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
                if (notes.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _CareNoteCard(
                          note: notes[index],
                          onDelete: () => _delete(notes[index]),
                          onEdit: () => _goToEdit(notes[index]),
                        ),
                        childCount: notes.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No care notes yet.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap Add Care Note to log one.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CareNoteCard extends StatelessWidget {
  final CareNoteModel note;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _CareNoteCard({
    required this.note,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.formattedDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              if (note.mood.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.moodBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    note.mood,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.moodColor,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.destructive,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Chip(
                icon: Icons.favorite_border,
                label: 'BP ${note.bloodPressureText}',
                color: AppColors.vitalsColor,
                bg: AppColors.vitalsBg,
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.bedtime_outlined,
                label: 'Sleep ${note.sleepText}',
                color: AppColors.primary,
                bg: AppColors.cyanBg,
              ),
            ],
          ),
          if (note.meals.isNotEmpty) ...[
            const SizedBox(height: 10),
            _LabeledText(label: 'Meals', value: note.meals),
          ],
          if (note.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _LabeledText(label: 'Notes', value: note.notes),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  final String label;
  final String value;
  const _LabeledText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: AppColors.foreground),
        ),
      ],
    );
  }
}
