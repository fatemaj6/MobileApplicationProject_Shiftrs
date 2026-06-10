import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/care_note_controller.dart';
import '../models/care_note_model.dart';
import 'add_care_note_screen.dart';
import 'edit_care_note_screen.dart';

class CareNoteListScreen extends StatefulWidget {
  final bool isFamilyView;
  final String? caregiverIdOverride;

  const CareNoteListScreen({
    super.key,
    this.isFamilyView = false,
    this.caregiverIdOverride,
  });

  @override
  State<CareNoteListScreen> createState() => _CareNoteListScreenState();
}

class _CareNoteListScreenState extends State<CareNoteListScreen> {
  final CareNoteController _controller = CareNoteController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Vitals',
    'Meals',
    'Mood',
    'Sleep',
    'General',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Care note deleted.' : 'Delete failed.'),
        backgroundColor: ok ? AppColors.given : AppColors.destructive,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<CareNoteModel> _applyFilters(List<CareNoteModel> notes, String query) {
    final cleanQuery = query.trim().toLowerCase();

    return notes.where((note) {
      final matchesCategory =
          _selectedCategory == 'All' || note.category == _selectedCategory;

      final searchableText = [
        note.category,
        note.title,
        note.displayTitle,
        note.meals,
        note.mood,
        note.notes,
        note.bloodPressureText,
        note.sleepText,
        note.formattedDate,
      ].join(' ').toLowerCase();

      final matchesSearch =
          cleanQuery.isEmpty || searchableText.contains(cleanQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int _countCategory(List<CareNoteModel> notes, String category) {
    if (category == 'All') return notes.length;
    return notes.where((note) => note.category == category).length;
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isFamilyView ? AppColors.purple : AppColors.primary;
    final activeBg = widget.isFamilyView ? AppColors.purpleBg : AppColors.cyanBg;

    final stream = _controller.streamCareNotes(
      caregiverIdOverride: widget.caregiverIdOverride,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<CareNoteModel>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.destructive),
                ),
              );
            }

            final allNotes = snapshot.data ?? [];

            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                final filteredNotes = _applyFilters(allNotes, value.text);

                return CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 22),

                            if (!widget.isFamilyView) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  onPressed: _goToAdd,
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Add Care Note',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: activeColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            _SearchBox(
                              controller: _searchController,
                              activeColor: activeColor,
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              height: 48,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final category = _categories[index];
                                  final selected =
                                      _selectedCategory == category;

                                  return _FilterChip(
                                    label: category,
                                    count: _countCategory(allNotes, category),
                                    selected: selected,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                    },
                                    icon: _categoryIcon(category),
                                    activeColor: activeColor,
                                    activeBg: activeBg,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),
                    ),

                    if (allNotes.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else if (filteredNotes.isEmpty)
                      SliverFillRemaining(child: _buildNoResultsState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final note = filteredNotes[index];

                              return _CareNoteCard(
                                note: note,
                                isFamilyView: widget.isFamilyView,
                                onEdit: () => _goToEdit(note),
                                onDelete: () => _delete(note),
                              );
                            },
                            childCount: filteredNotes.length,
                          ),
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

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Care Notes',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isFamilyView
                    ? 'Daily updates shared by the caregiver'
                    : 'Daily activity log for the patient',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 70,
              color: AppColors.textMuted.withOpacity(0.55),
            ),
            const SizedBox(height: 16),
            const Text(
              'No care notes yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isFamilyView
                  ? 'Care notes shared by the caregiver will appear here.'
                  : 'Tap Add Care Note to start recording daily updates.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'No notes match your search or filter.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Vitals':
        return Icons.favorite_border;
      case 'Meals':
        return Icons.restaurant_outlined;
      case 'Mood':
        return Icons.mood_outlined;
      case 'Sleep':
        return Icons.bedtime_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final Color activeColor;

  const _SearchBox({
    required this.controller,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search notes...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: controller.clear,
              ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: activeColor, width: 1.3),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color activeColor;
  final Color activeBg;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.activeColor,
    required this.activeBg,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? activeColor : AppColors.card;
    final textColor = selected ? Colors.white : AppColors.foreground;
    final iconBg = selected ? Colors.white.withOpacity(0.2) : activeBg;
    final iconColor = selected ? Colors.white : activeColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? activeColor : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareNoteCard extends StatelessWidget {
  final CareNoteModel note;
  final bool isFamilyView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CareNoteCard({
    required this.note,
    required this.isFamilyView,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get icon {
    switch (note.category) {
      case 'Vitals':
        return Icons.favorite_border;
      case 'Meals':
        return Icons.restaurant_outlined;
      case 'Mood':
        return Icons.mood_outlined;
      case 'Sleep':
        return Icons.bedtime_outlined;
      default:
        return Icons.note_alt_outlined;
    }
  }

  Color get color {
    switch (note.category) {
      case 'Vitals':
        return AppColors.vitalsColor;
      case 'Mood':
        return AppColors.moodColor;
      case 'Meals':
        return AppColors.mealsColor;
      case 'Sleep':
        return AppColors.primary;
      default:
        return AppColors.generalColor;
    }
  }

  Color get bg {
    switch (note.category) {
      case 'Vitals':
        return AppColors.vitalsBg;
      case 'Mood':
        return AppColors.moodBg;
      case 'Meals':
        return AppColors.mealsBg;
      case 'Sleep':
        return AppColors.cyanBg;
      default:
        return AppColors.generalBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.displayTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    _CategoryBadge(text: note.category, color: color, bg: bg),
                  ],
                ),
                const SizedBox(height: 10),
                if (note.category == 'Vitals')
                  _InfoLine(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Blood Pressure',
                    value: note.bloodPressureText,
                  ),
                if (note.category == 'Meals' && note.meals.isNotEmpty)
                  _InfoLine(
                    icon: Icons.restaurant_outlined,
                    label: 'Meals',
                    value: note.meals,
                  ),
                if (note.category == 'Mood' && note.mood.isNotEmpty)
                  _InfoLine(
                    icon: Icons.mood_outlined,
                    label: 'Mood',
                    value: note.mood,
                  ),
                if (note.category == 'Sleep')
                  _InfoLine(
                    icon: Icons.bedtime_outlined,
                    label: 'Sleep',
                    value: note.sleepText,
                  ),
                if (note.notes.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    note.notes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      note.formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isFamilyView)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.foreground),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;

  const _CategoryBadge({
    required this.text,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.foreground,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}