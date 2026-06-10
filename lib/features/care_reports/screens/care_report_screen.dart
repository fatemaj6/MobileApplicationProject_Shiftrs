import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/care_report_controller.dart';
import '../models/care_report_model.dart';
import '../services/care_report_pdf_service.dart'; // SMAP-34 PDF
import '../../../features/appointments/models/appointment_model.dart';
import '../../../data/model/medication_model.dart';

class CareReportScreen extends StatefulWidget {
  /// When opened by a family member, pass [isFamily] = true and the
  /// [linkedCaregiverId] so the report fetches the caregiver's data.
  const CareReportScreen({
    super.key,
    this.isFamily = false,
    this.linkedCaregiverId,
  });

  final bool isFamily;
  final String? linkedCaregiverId;

  @override
  State<CareReportScreen> createState() => _CareReportScreenState();
}

class _CareReportScreenState extends State<CareReportScreen> {
  final _controller = CareReportController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _reportGenerated = false;
  bool _isPdfLoading = false;
  String _selectedCategory = 'All';

final List<String> _categories = [
  'All',
  'Appointments',
  'Medications',
];

  // ─── Date pickers ─────────────────────────────────────────────────────────

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select start date',
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select end date',
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColors.primary),
      ),
      child: child!,
    );
  }

  // ─── Generate ─────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    final validationError =
        _controller.validateDateRange(_startDate, _endDate);
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }
    setState(() => _reportGenerated = false);
    final ok = await _controller.generateReport(
  startDate: _startDate!,
  endDate: _endDate!,
  linkedCaregiverId: widget.linkedCaregiverId,
  selectedCategory: _selectedCategory,
);
    if (mounted) {
      setState(() => _reportGenerated = ok);
      if (!ok) {
        _showSnackBar(
          _controller.errorMessage ?? 'Failed to generate report.',
          isError: true,
        );
      }
    }
  }

  // ─── PDF actions ──────────────────────────────────────────────────────────

  Future<void> _downloadPdf() async {
    final report = _controller.report;
    if (report == null) return;
    setState(() => _isPdfLoading = true);
    final ok = await CareReportPdfService.downloadReport(report);
    if (mounted) {
      setState(() => _isPdfLoading = false);
      if (!ok) _showSnackBar('Failed to generate PDF.', isError: true);
    }
  }

  Future<void> _previewPdf() async {
    final report = _controller.report;
    if (report == null) return;
    setState(() => _isPdfLoading = true);
    final ok = await CareReportPdfService.previewReport(report);
    if (mounted) {
      setState(() => _isPdfLoading = false);
      if (!ok) _showSnackBar('Failed to open preview.', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.destructive : AppColors.given,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateRangeCard(),
                        const SizedBox(height: 20),
                        if (_controller.isLoading) _buildLoading(),
                        if (_reportGenerated && _controller.report != null) ...[
                          _ReportView(
                            report: _controller.report!,
                            onDownload: _isPdfLoading ? null : _downloadPdf,
                            onPreview: _isPdfLoading ? null : _previewPdf,
                            isPdfLoading: _isPdfLoading,
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final bool isFamily = widget.isFamily;
    final headerColors = isFamily
        ? [AppColors.purpleLight, AppColors.purple]
        : [AppColors.primaryLight, AppColors.primary];

    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: headerColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Care Summary Report',
                    style: AppTextStyles.h3
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    isFamily
                        ? "Viewing your caregiver's care data"
                        : 'Select a date range to generate',
                    style: AppTextStyles.secondarySm
                        .copyWith(color: Colors.white70),
                  ),
                  if (isFamily) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Family View · Read-only',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              child: Icon(Icons.summarize_outlined,
                  color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Date range card ──────────────────────────────────────────────────────

  Widget _buildDateRangeCard() {
    final fmt = DateFormat('d MMM yyyy');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date Range', style: AppTextStyles.h4),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Start Date',
                  value: _startDate != null ? fmt.format(_startDate!) : null,
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'End Date',
                  value: _endDate != null ? fmt.format(_endDate!) : null,
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),
                    const SizedBox(height: 18),

          Text('Category Filter', style: AppTextStyles.h4),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;

              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                selectedColor: AppColors.purple.withOpacity(0.16),
                backgroundColor: AppColors.background,
                side: BorderSide(
                  color: isSelected ? AppColors.purple : AppColors.border,
                ),
                labelStyle: AppTextStyles.bodySm.copyWith(
                  color: isSelected
                      ? AppColors.purple
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _controller.isLoading ? null : _generate,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                _controller.isLoading ? 'Generating…' : 'Generate Report',
                style: AppTextStyles.button,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// ─── Date picker button ────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.secondarySm),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value ?? 'Select date',
                    style: value != null
                        ? AppTextStyles.bodyMd
                            .copyWith(fontWeight: FontWeight.w600)
                        : AppTextStyles.bodyMd
                            .copyWith(color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report View ──────────────────────────────────────────────────────────

class _ReportView extends StatelessWidget {
  final CareReportModel report;
  final VoidCallback? onDownload;
  final VoidCallback? onPreview;
  final bool isPdfLoading;

  const _ReportView({
    required this.report,
    this.onDownload,
    this.onPreview,
    this.isPdfLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Report header banner ────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECFEFF), Color(0xFFCFFAFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child:
                        Icon(Icons.summarize, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Care Summary Report',
                            style: AppTextStyles.h4
                                .copyWith(color: AppColors.primary)),
                        Text(
                          '${fmt.format(report.startDate)} – ${fmt.format(report.endDate)}',
                          style: AppTextStyles.secondarySm,
                        ),
                        Text(
                          'Generated ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
                          style: AppTextStyles.secondarySm
                              .copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // ── Download / Share / Preview action row ───────────────
              const SizedBox(height: 14),
              if (isPdfLoading)
                const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDownload,
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('Download PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: AppTextStyles.bodySm
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPreview,
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            size: 16),
                        label: const Text('Preview / Print'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.purple,
                          side: const BorderSide(color: AppColors.purple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: AppTextStyles.bodySm
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        if (report.isEmpty) ...[
          const SizedBox(height: 24),
          _EmptyReport(),
        ] else ...[
          const SizedBox(height: 20),

if (report.medications.isNotEmpty) ...[
  _MedicationSummarySection(report: report),
  const SizedBox(height: 20),
],

if (report.appointments.isNotEmpty) ...[
  _AppointmentSummarySection(report: report),
  const SizedBox(height: 20),
],

if (report.medications.isNotEmpty) ...[
            const SizedBox(height: 20),
            _MedicationDetailSection(medications: report.medications),
          ],
          if (report.appointments.isNotEmpty) ...[
            const SizedBox(height: 20),
            _AppointmentDetailSection(appointments: report.appointments),
          ],
        ],
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────

class _EmptyReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('No records found', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(
            'No appointments or medications were recorded\nin the selected date range.',
            style: AppTextStyles.secondarySm,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Medication summary ───────────────────────────────────────────────────

class _MedicationSummarySection extends StatelessWidget {
  final CareReportModel report;
  const _MedicationSummarySection({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Medication Adherence',
      icon: Icons.medication_outlined,
      iconColor: AppColors.given,
      child: Column(
        children: [
          _ProgressRow(
            label: 'Adherence Rate',
            value: '${report.adherencePercentage.toStringAsFixed(0)}%',
            progress: report.adherencePercentage / 100,
            color: report.adherencePercentage >= 80
                ? AppColors.given
                : AppColors.alertAmber,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _StatChip(
                      label: 'Given',
                      value: report.givenMedications,
                      color: AppColors.given,
                      bg: AppColors.givenBg)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatChip(
                      label: 'Missed',
                      value: report.missedMedications,
                      color: AppColors.destructive,
                      bg: AppColors.missedBg)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatChip(
                      label: 'Pending',
                      value: report.pendingMedications,
                      color: AppColors.pending,
                      bg: AppColors.pendingBg)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Appointment summary ──────────────────────────────────────────────────

class _AppointmentSummarySection extends StatelessWidget {
  final CareReportModel report;
  const _AppointmentSummarySection({required this.report});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Appointment Summary',
      icon: Icons.calendar_month_outlined,
      iconColor: AppColors.primary,
      child: Row(
        children: [
          Expanded(
              child: _StatChip(
                  label: 'Upcoming',
                  value: report.upcomingAppointments,
                  color: AppColors.primary,
                  bg: AppColors.cyanBg)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatChip(
                  label: 'Past',
                  value: report.pastAppointments,
                  color: AppColors.textSecondary,
                  bg: AppColors.borderLight)),
          const SizedBox(width: 8),
          Expanded(
              child: _StatChip(
                  label: 'Cancelled',
                  value: report.cancelledAppointments,
                  color: AppColors.destructive,
                  bg: AppColors.missedBg)),
        ],
      ),
    );
  }
}

// ─── Medication detail list ───────────────────────────────────────────────

class _MedicationDetailSection extends StatelessWidget {
  final List<MedicationModel> medications;
  const _MedicationDetailSection({required this.medications});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Medication Records (${medications.length})',
      icon: Icons.list_alt_outlined,
      iconColor: AppColors.alertAmber,
      child: Column(
        children: medications
            .map((m) => _MedicationRow(medication: m))
            .toList(),
      ),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  final MedicationModel medication;
  const _MedicationRow({required this.medication});

  Color get _statusColor {
    switch (medication.status) {
      case 'given':
        return AppColors.given;
      case 'missed':
        return AppColors.destructive;
      default:
        return AppColors.pending;
    }
  }

  Color get _statusBg {
    switch (medication.status) {
      case 'given':
        return AppColors.givenBg;
      case 'missed':
        return AppColors.missedBg;
      default:
        return AppColors.pendingBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('${medication.dosage} · ${medication.frequency} · ${medication.time}',
                    style: AppTextStyles.secondarySm),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              medication.status.toUpperCase(),
              style: AppTextStyles.bodySm.copyWith(
                color: _statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Appointment detail list ──────────────────────────────────────────────

class _AppointmentDetailSection extends StatelessWidget {
  final List<AppointmentModel> appointments;
  const _AppointmentDetailSection({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Appointment Records (${appointments.length})',
      icon: Icons.event_note_outlined,
      iconColor: AppColors.purple,
      child: Column(
        children: appointments
            .map((a) => _AppointmentRow(appointment: a))
            .toList(),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentRow({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final statusColor = appointment.status == 'cancelled'
        ? AppColors.destructive
        : appointment.isPast
            ? AppColors.textSecondary
            : AppColors.primary;
    final statusBg = appointment.status == 'cancelled'
        ? AppColors.missedBg
        : appointment.isPast
            ? AppColors.borderLight
            : AppColors.cyanBg;
    final statusLabel = appointment.status == 'cancelled'
        ? 'CANCELLED'
        : appointment.isPast
            ? 'PAST'
            : 'UPCOMING';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cyanBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                Text(appointment.dayNumber,
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.primary, fontSize: 15)),
                Text(appointment.shortMonth,
                    style: AppTextStyles.secondarySm
                        .copyWith(color: AppColors.primary, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.title,
                    style: AppTextStyles.bodyMd
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                    '${appointment.clinicName} · ${appointment.formattedTime}',
                    style: AppTextStyles.secondarySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (appointment.doctorName.isNotEmpty)
                  Text('Dr. ${appointment.doctorName}',
                      style: AppTextStyles.secondarySm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: AppTextStyles.bodySm.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: iconColor.withOpacity(0.12),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.h4),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style:
                AppTextStyles.h2.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          Text(label, style: AppTextStyles.secondarySm),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.secondarySm),
            Text(value,
                style: AppTextStyles.bodyMd
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
