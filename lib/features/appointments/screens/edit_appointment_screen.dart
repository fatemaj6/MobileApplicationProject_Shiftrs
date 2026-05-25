import 'package:flutter/material.dart';

import '../controllers/appointment_controller.dart';
import '../models/appointment_model.dart';

class EditAppointmentScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const EditAppointmentScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final AppointmentController _controller = AppointmentController();

  late final TextEditingController _titleController;
  late final TextEditingController _clinicController;
  late final TextEditingController _doctorController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _notesController;

  late String _appointmentType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final List<String> _appointmentTypes = const [
    'Check-up',
    'Specialist',
    'Lab Test',
    'Therapy',
    'Follow-up',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    final appointment = widget.appointment;

    _titleController = TextEditingController(text: appointment.title);
    _clinicController = TextEditingController(text: appointment.clinicName);
    _doctorController = TextEditingController(text: appointment.doctorName);
    _specialtyController = TextEditingController(text: appointment.specialty);
    _notesController = TextEditingController(text: appointment.notes);

    _appointmentType = _appointmentTypes.contains(appointment.appointmentType)
        ? appointment.appointmentType
        : 'Check-up';

    _selectedDate = appointment.appointmentDateTime;
    _selectedTime = TimeOfDay.fromDateTime(appointment.appointmentDateTime);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clinicController.dispose();
    _doctorController.dispose();
    _specialtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime _combineDateAndTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final appointmentDateTime = _combineDateAndTime();

    final updatedAppointment = widget.appointment.copyWith(
      title: _titleController.text.trim(),
      clinicName: _clinicController.text.trim(),
      doctorName: _doctorController.text.trim(),
      specialty: _specialtyController.text.trim(),
      appointmentType: _appointmentType,
      appointmentDateTime: appointmentDateTime,
      notes: _notesController.text.trim(),
      status: appointmentDateTime.isBefore(DateTime.now()) ? 'past' : 'upcoming',
    );

    final success = await _controller.updateAppointment(updatedAppointment);

    if (!mounted) return;

    if (success) {
      _showSnackBar('Appointment updated successfully.');
      Navigator.pop(context);
    } else {
      _showSnackBar(
        _controller.errorMessage ?? 'Failed to update appointment.',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _dateText() {
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  String _timeText() {
    return _selectedTime.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F5F9),
        elevation: 0,
        title: const Text(
          'Edit Appointment',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Appointment Title / Doctor Name *',
                  hint: 'e.g., Dr. Tan Check-up',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Appointment title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _clinicController,
                  label: 'Clinic or Hospital Name *',
                  hint: 'e.g., Gleneagles Hospital Kuala Lumpur',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Clinic or hospital name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _doctorController,
                  label: 'Doctor Name',
                  hint: 'e.g., Dr. Tan',
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _specialtyController,
                  label: 'Doctor Details / Specialty',
                  hint: 'e.g., Cardiology',
                ),
                const SizedBox(height: 14),
                _buildDropdown(),
                const SizedBox(height: 14),
                _buildPickerTile(
                  label: 'Date *',
                  value: _dateText(),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 14),
                _buildPickerTile(
                  label: 'Time *',
                  value: _timeText(),
                  icon: Icons.access_time,
                  onTap: _pickTime,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes / Instructions',
                  hint: 'e.g., Bring previous reports',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _controller.isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0891B2),
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
                    style: TextStyle(color: Color(0xFF64748B)),
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF0891B2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointment Type *',
          style: TextStyle(
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: _appointmentType,
          items: _appointmentTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _appointmentType = value;
              });
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF0891B2)),
            ),
          ),
        ),
      ],
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
            color: Color(0xFF475569),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Color(0xFF1E293B)),
                  ),
                ),
                Icon(icon, color: const Color(0xFF0891B2), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}