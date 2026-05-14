import 'package:flutter/material.dart';
import '../../../data/model/medication_model.dart';
import '../controllers/medication_controller.dart';

/// Screen for adding a new medication.
/// Validates all required fields before saving to Firestore.
class AddMedicationScreen extends StatefulWidget {
  final String patientId;
  final String caregiverId;

  const AddMedicationScreen({
    super.key,
    required this.patientId,
    required this.caregiverId,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicationController _controller = MedicationController();

  // ─── Controllers ──────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedFrequency = 'Once daily';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Every 4 hours',
    'Every 6 hours',
    'Every 8 hours',
    'As needed',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  // ─── Time picker ──────────────────────────────────────────────────────────

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String get _formattedTime => _selectedTime.format(context);

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final medication = MedicationModel(
      id: '',
      caregiverId: widget.caregiverId,
      patientId: widget.patientId,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _selectedFrequency,
      time: _formattedTime,
      instructions: _instructionsController.text.trim(),
      status: 'pending',
    );

    final ok = await _controller.addMedication(medication);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Medication added successfully.'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Something went wrong.'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Medication',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication Name
              _buildLabel('Medication Name *'),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g., Metformin',
                validator: (v) =>
                    _controller.validateRequired(v, 'Medication name'),
              ),
              const SizedBox(height: 16),

              // Dosage
              _buildLabel('Dosage *'),
              _buildTextField(
                controller: _dosageController,
                hint: 'e.g., 500mg',
                validator: (v) => _controller.validateRequired(v, 'Dosage'),
              ),
              const SizedBox(height: 16),

              // Frequency dropdown
              _buildLabel('Frequency *'),
              _buildDropdown(),
              const SizedBox(height: 16),

              // Time
              _buildLabel('Time *'),
              _buildTimePicker(),
              const SizedBox(height: 16),

              // Instructions
              _buildLabel('Instructions (Optional)'),
              _buildTextField(
                controller: _instructionsController,
                hint: 'e.g., Take with food',
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Add Medication button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Add Medication',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Reusable widgets ─────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0891B2), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFrequency,
      validator: (v) => _controller.validateRequired(v, 'Frequency'),
      onChanged: (val) => setState(() => _selectedFrequency = val!),
      items: _frequencies
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0891B2), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formattedTime,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF1E293B)),
              ),
            ),
            const Icon(Icons.access_time,
                size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}