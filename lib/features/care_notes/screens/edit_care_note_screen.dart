import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/care_note_controller.dart';
import '../models/care_note_model.dart';

class EditCareNoteScreen extends StatefulWidget {
  final CareNoteModel note;
  const EditCareNoteScreen({super.key, required this.note});

  @override
  State<EditCareNoteScreen> createState() => _EditCareNoteScreenState();
}

class _EditCareNoteScreenState extends State<EditCareNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final CareNoteController _controller = CareNoteController();

  late final TextEditingController _mealsController;
  late final TextEditingController _systolicController;
  late final TextEditingController _diastolicController;
  late final TextEditingController _sleepController;
  late final TextEditingController _notesController;

  String? _selectedMood;
  late DateTime _selectedDate;

  static const List<String> _moodOptions = [
    'Happy',
    'Calm',
    'Anxious',
    'Sad',
    'Irritable',
    'Unwell',
  ];

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _mealsController = TextEditingController(text: note.meals);
    _systolicController = TextEditingController(
      text: note.systolic?.toString() ?? '',
    );
    _diastolicController = TextEditingController(
      text: note.diastolic?.toString() ?? '',
    );
    _sleepController = TextEditingController(
      text: note.sleepHours?.toString() ?? '',
    );
    _notesController = TextEditingController(text: note.notes);
    // guard against a unlisted mood
    _selectedMood = _moodOptions.contains(note.mood) ? note.mood : null;
    _selectedDate = note.date;
  }

  @override
  void dispose() {
    _mealsController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _sleepController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _hasAnyEntry =>
      _mealsController.text.trim().isNotEmpty ||
      (_selectedMood != null && _selectedMood!.isNotEmpty) ||
      _systolicController.text.trim().isNotEmpty ||
      _diastolicController.text.trim().isNotEmpty ||
      _sleepController.text.trim().isNotEmpty ||
      _notesController.text.trim().isNotEmpty;

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasAnyEntry) {
      _showSnackBar('Please fill in at least one field.', isError: true);
      return;
    }

    final updated = CareNoteModel(
      id: widget.note.id,
      caregiverId: widget.note.caregiverId,
      patientId: widget.note.patientId,
      date: _selectedDate,
      meals: _mealsController.text.trim(),
      mood: _selectedMood ?? '',
      systolic: int.tryParse(_systolicController.text.trim()),
      diastolic: int.tryParse(_diastolicController.text.trim()),
      sleepHours: double.tryParse(_sleepController.text.trim()),
      notes: _notesController.text.trim(),
      isDeleted: widget.note.isDeleted,
      createdAt: widget.note.createdAt,
    );

    final success = await _controller.updateCareNote(updated);
    if (!mounted) return;

    if (success) {
      _showSnackBar('Care note updated successfully.');
      Navigator.pop(context);
    } else {
      _showSnackBar(
        _controller.errorMessage ?? 'Failed to update care note.',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.destructive : AppColors.given,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _validateNumber(String? value, {required String field, int? max}) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = num.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number for $field.';
    if (parsed <= 0) return '$field must be greater than 0.';
    if (max != null && parsed > max) return '$field seems too high.';
    return null;
  }

  String _dateText() =>
      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Edit Care Note',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.foreground),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _mealsController,
                  label: 'Meals',
                  hint: 'e.g., Breakfast: oats; Lunch: rice & veg',
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                _buildMoodDropdown(),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _systolicController,
                        label: 'Systolic (BP)',
                        hint: 'e.g., 120',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _validateNumber(v, field: 'Systolic', max: 300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _diastolicController,
                        label: 'Diastolic (BP)',
                        hint: 'e.g., 80',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _validateNumber(v, field: 'Diastolic', max: 200),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _sleepController,
                  label: 'Sleep (hours)',
                  hint: 'e.g., 7.5',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => _validateNumber(v, field: 'Sleep', max: 24),
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _notesController,
                  label: 'Additional Notes',
                  hint: 'Anything else worth recording',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _controller.isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textLabel,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: _inputDecoration(hint),
        ),
      ],
    );
  }

  Widget _buildMoodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mood',
          style: TextStyle(
            color: AppColors.textLabel,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: _selectedMood,
          hint: const Text('Select mood'),
          items: _moodOptions
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (value) => setState(() => _selectedMood = value),
          decoration: _inputDecoration(''),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textLabel,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: AppColors.foreground),
                  ),
                ),
                Icon(icon, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
