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

  late final TextEditingController _titleController;
  late final TextEditingController _mealsController;
  late final TextEditingController _systolicController;
  late final TextEditingController _diastolicController;
  late final TextEditingController _sleepController;
  late final TextEditingController _notesController;

  late String _selectedCategory;
  String? _selectedMood;
  late DateTime _selectedDate;

  static const List<String> _categories = [
    'Vitals',
    'Meals',
    'Mood',
    'Sleep',
    'General',
  ];

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

    _selectedCategory = _categories.contains(note.category)
        ? note.category
        : 'General';

    _selectedDate = note.date;
    _selectedMood = _moodOptions.contains(note.mood) ? note.mood : null;

    _titleController = TextEditingController(text: note.title);
    _mealsController = TextEditingController(text: note.meals);
    _systolicController =
        TextEditingController(text: note.systolic?.toString() ?? '');
    _diastolicController =
        TextEditingController(text: note.diastolic?.toString() ?? '');
    _sleepController =
        TextEditingController(text: note.sleepHours?.toString() ?? '');
    _notesController = TextEditingController(text: note.notes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mealsController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _sleepController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = CareNoteModel(
      id: widget.note.id,
      caregiverId: widget.note.caregiverId,
      patientId: widget.note.patientId,
      date: _selectedDate,
      category: _selectedCategory,
      title: _titleController.text.trim(),
      meals: _selectedCategory == 'Meals' ? _mealsController.text.trim() : '',
      mood: _selectedCategory == 'Mood' ? (_selectedMood ?? '') : '',
      systolic: _selectedCategory == 'Vitals'
          ? int.tryParse(_systolicController.text.trim())
          : null,
      diastolic: _selectedCategory == 'Vitals'
          ? int.tryParse(_diastolicController.text.trim())
          : null,
      sleepHours: _selectedCategory == 'Sleep'
          ? double.tryParse(_sleepController.text.trim())
          : null,
      notes: _notesController.text.trim(),
      isDeleted: widget.note.isDeleted,
      createdAt: widget.note.createdAt,
      updatedAt: widget.note.updatedAt,
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

  void _changeCategory(String? value) {
    if (value == null) return;

    setState(() {
      _selectedCategory = value;
      _selectedMood = null;
      _mealsController.clear();
      _systolicController.clear();
      _diastolicController.clear();
      _sleepController.clear();
      _notesController.clear();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
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

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }
    return null;
  }

  String? _validateRequiredNumber(
    String? value, {
    required String field,
    int? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }

    final parsed = num.tryParse(value.trim());

    if (parsed == null) return 'Enter a valid number for $field.';
    if (parsed <= 0) return '$field must be greater than 0.';
    if (max != null && parsed > max) return '$field seems too high.';

    return null;
  }

  String _dateText() {
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
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
        return Icons.note_alt_outlined;
    }
  }

  String _titleHint() {
    switch (_selectedCategory) {
      case 'Vitals':
        return 'e.g., Morning Blood Pressure';
      case 'Meals':
        return 'e.g., Breakfast Intake';
      case 'Mood':
        return 'e.g., Cheerful Mood Today';
      case 'Sleep':
        return 'e.g., Night Sleep Update';
      default:
        return 'e.g., General Care Update';
    }
  }

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
                _buildPickerTile(
                  label: 'Date *',
                  value: _dateText(),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 14),

                _buildCategoryDropdown(),
                const SizedBox(height: 14),

                _buildTextField(
                  controller: _titleController,
                  label: 'Title *',
                  hint: _titleHint(),
                  validator: (v) => _required(v, 'Title'),
                ),
                const SizedBox(height: 14),

                ..._buildDynamicFields(),

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

  List<Widget> _buildDynamicFields() {
    if (_selectedCategory == 'Vitals') {
      return [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _systolicController,
                label: 'Systolic (BP) *',
                hint: 'e.g., 120',
                keyboardType: TextInputType.number,
                validator: (v) => _validateRequiredNumber(
                  v,
                  field: 'Systolic BP',
                  max: 300,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _diastolicController,
                label: 'Diastolic (BP) *',
                hint: 'e.g., 80',
                keyboardType: TextInputType.number,
                validator: (v) => _validateRequiredNumber(
                  v,
                  field: 'Diastolic BP',
                  max: 200,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _notesController,
          label: 'Additional Notes',
          hint: 'e.g., Slightly elevated but stable',
          maxLines: 4,
        ),
      ];
    }

    if (_selectedCategory == 'Meals') {
      return [
        _buildTextField(
          controller: _mealsController,
          label: 'Meals *',
          hint: 'e.g., Breakfast: oats; Lunch: rice & veg',
          maxLines: 4,
          validator: (v) => _required(v, 'Meals'),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _notesController,
          label: 'Additional Notes',
          hint: 'e.g., Good appetite this morning',
          maxLines: 4,
        ),
      ];
    }

    if (_selectedCategory == 'Mood') {
      return [
        _buildMoodDropdown(),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _notesController,
          label: 'Additional Notes',
          hint: 'e.g., Calm and talkative today',
          maxLines: 4,
        ),
      ];
    }

    if (_selectedCategory == 'Sleep') {
      return [
        _buildTextField(
          controller: _sleepController,
          label: 'Sleep (hours) *',
          hint: 'e.g., 7.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => _validateRequiredNumber(
            v,
            field: 'Sleep hours',
            max: 24,
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _notesController,
          label: 'Additional Notes',
          hint: 'e.g., Woke up twice during the night',
          maxLines: 4,
        ),
      ];
    }

    return [
      _buildTextField(
        controller: _notesController,
        label: 'Details *',
        hint: 'Anything else worth recording',
        maxLines: 5,
        validator: (v) => _required(v, 'Details'),
      ),
    ];
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            color: AppColors.textLabel,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          items: _categories
              .map(
                (category) => DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        _categoryIcon(category),
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: _changeCategory,
          decoration: _inputDecoration('Select category'),
        ),
      ],
    );
  }

  Widget _buildMoodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mood *',
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
          validator: (v) => v == null || v.isEmpty ? 'Mood is required.' : null,
          decoration: _inputDecoration(''),
        ),
      ],
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