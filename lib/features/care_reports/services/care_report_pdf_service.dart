import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/care_report_model.dart';
import '../../../features/appointments/models/appointment_model.dart';
import '../../../data/model/medication_model.dart';

/// Service responsible for building a PDF from a [CareReportModel] and
/// triggering the system share/download sheet via the [printing] package.
class CareReportPdfService {
  // ── Color palette (mirrors AppColors using PdfColor) ──────────────────────
  static const _primary = PdfColor.fromInt(0xFF0891B2); // cyan-600
  static const _purple = PdfColor.fromInt(0xFF9333EA);
  static const _given = PdfColor.fromInt(0xFF16A34A); // green
  static const _missed = PdfColor.fromInt(0xFFDC2626); // red
  static const _pending = PdfColor.fromInt(0xFF6B7280); // gray
  static const _textDark = PdfColor.fromInt(0xFF111827);
  static const _textGray = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _bg = PdfColor.fromInt(0xFFF9FAFB);
  static const _white = PdfColors.white;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Generates the PDF and opens the system print/share/download dialog.
  /// Returns true on success.
  static Future<bool> downloadReport(CareReportModel report) async {
    try {
      final pdf = await _buildPdf(report);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: _filename(report),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Generates the PDF and opens the system print preview (also allows save).
  static Future<bool> previewReport(CareReportModel report) async {
    try {
      final pdf = await _buildPdf(report);
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: _filename(report),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static String _filename(CareReportModel report) {
    final fmt = DateFormat('yyyyMMdd');
    return 'CareConnect_Report_${fmt.format(report.startDate)}_${fmt.format(report.endDate)}.pdf';
  }

  static Future<pw.Document> _buildPdf(CareReportModel report) async {
    final pdf = pw.Document(
      title: 'CareConnect — Care Summary Report',
      author: 'CareConnect',
    );

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontSemiBold = await PdfGoogleFonts.interSemiBold();

    final dateFmt = DateFormat('d MMM yyyy');
    final nowFmt = DateFormat('d MMM yyyy, h:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          buildBackground: (_) => pw.Container(color: _white),
        ),
        header: (_) => _buildHeader(
          fontBold,
          fontSemiBold,
          dateFmt.format(report.startDate),
          dateFmt.format(report.endDate),
          nowFmt.format(DateTime.now()),
        ),
        footer: (ctx) => _buildFooter(font, ctx.pageNumber, ctx.pagesCount),
        build: (context) => [
          pw.SizedBox(height: 16),
          // ── Summary stats ──────────────────────────────────────────────
          _sectionTitle('Medication Adherence', fontBold),
          pw.SizedBox(height: 8),
          _medicationSummaryTable(report, fontBold, fontSemiBold, font),
          pw.SizedBox(height: 18),
          _sectionTitle('Appointment Summary', fontBold),
          pw.SizedBox(height: 8),
          _appointmentSummaryTable(report, fontBold, font),
          pw.SizedBox(height: 18),
          // ── Detail tables ──────────────────────────────────────────────
          if (report.medications.isNotEmpty) ...[
            _sectionTitle(
                'Medication Records (${report.medications.length})', fontBold),
            pw.SizedBox(height: 8),
            _medicationDetailTable(report.medications, fontBold, font),
            pw.SizedBox(height: 18),
          ],
          if (report.appointments.isNotEmpty) ...[
            _sectionTitle(
                'Appointment Records (${report.appointments.length})',
                fontBold),
            pw.SizedBox(height: 8),
            _appointmentDetailTable(report.appointments, fontBold, font),
          ],
          if (report.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 40),
                child: pw.Text(
                  'No records found in the selected date range.',
                  style: pw.TextStyle(font: font, color: _textGray),
                ),
              ),
            ),
        ],
      ),
    );

    return pdf;
  }

  // ── Page header ────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    pw.Font bold,
    pw.Font semiBold,
    String from,
    String to,
    String generated,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: _primary, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CareConnect',
                style: pw.TextStyle(
                    font: bold, fontSize: 18, color: _primary),
              ),
              pw.Text(
                'Care Summary Report',
                style: pw.TextStyle(
                    font: semiBold, fontSize: 11, color: _textDark),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Period: $from – $to',
                style: pw.TextStyle(font: semiBold, fontSize: 9),
              ),
              pw.Text(
                'Generated: $generated',
                style: pw.TextStyle(
                    font: semiBold, fontSize: 8, color: _textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Page footer ────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(
      pw.Font font, int pageNumber, int pagesCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(color: _border, width: 0.5))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Confidential — CareConnect Healthcare Summary',
            style: pw.TextStyle(font: font, fontSize: 7, color: _textGray),
          ),
          pw.Text(
            'Page $pageNumber of $pagesCount',
            style: pw.TextStyle(font: font, fontSize: 7, color: _textGray),
          ),
        ],
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String title, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: bold, fontSize: 10, color: _white),
      ),
    );
  }

  // ── Medication summary table ───────────────────────────────────────────────

  static pw.Widget _medicationSummaryTable(
    CareReportModel report,
    pw.Font bold,
    pw.Font semiBold,
    pw.Font regular,
  ) {
    final adherence =
        '${report.adherencePercentage.toStringAsFixed(1)}%';

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          // Adherence bar row
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Adherence Rate',
                        style: pw.TextStyle(font: semiBold, fontSize: 9)),
                    pw.Text(adherence,
                        style: pw.TextStyle(
                            font: bold,
                            fontSize: 9,
                            color: report.adherencePercentage >= 80
                                ? _given
                                : _missed)),
                  ],
                ),
                pw.SizedBox(height: 4),
                // Progress bar
                pw.Stack(children: [
                  pw.Container(
                      height: 7,
                      decoration: pw.BoxDecoration(
                          color: _border,
                          borderRadius: pw.BorderRadius.circular(4))),
                  pw.Container(
                    height: 7,
                    width: (PdfPageFormat.a4.availableWidth - 64) *
                        (report.adherencePercentage / 100).clamp(0, 1),
                    decoration: pw.BoxDecoration(
                      color: report.adherencePercentage >= 80
                          ? _given
                          : _missed,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          pw.Divider(height: 0, color: _border),
          // Stat chips row
          pw.Row(
            children: [
              _statCell('Given', report.givenMedications, _given, bold,
                  regular),
              _verticalDivider(),
              _statCell('Missed', report.missedMedications, _missed, bold,
                  regular),
              _verticalDivider(),
              _statCell('Pending', report.pendingMedications, _pending,
                  bold, regular),
              _verticalDivider(),
              _statCell(
                  'Total', report.totalMedications, _primary, bold, regular),
            ],
          ),
        ],
      ),
    );
  }

  // ── Appointment summary table ──────────────────────────────────────────────

  static pw.Widget _appointmentSummaryTable(
    CareReportModel report,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          _statCell('Upcoming', report.upcomingAppointments, _primary, bold,
              regular),
          _verticalDivider(),
          _statCell('Past', report.pastAppointments, _textGray, bold,
              regular),
          _verticalDivider(),
          _statCell('Cancelled', report.cancelledAppointments, _missed,
              bold, regular),
          _verticalDivider(),
          _statCell('Total', report.totalAppointments, _purple, bold,
              regular),
        ],
      ),
    );
  }

  static pw.Widget _statCell(
    String label,
    int value,
    PdfColor color,
    pw.Font bold,
    pw.Font regular,
  ) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: pw.Column(
          children: [
            pw.Text(
              value.toString(),
              style:
                  pw.TextStyle(font: bold, fontSize: 16, color: color),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: pw.TextStyle(
                  font: regular, fontSize: 8, color: _textGray),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _verticalDivider() {
    return pw.Container(
      width: 0.5,
      height: 50,
      color: _border,
    );
  }

  // ── Medication detail table ────────────────────────────────────────────────

  static pw.Widget _medicationDetailTable(
    List<MedicationModel> medications,
    pw.Font bold,
    pw.Font regular,
  ) {
    final headers = ['Medication', 'Dosage', 'Frequency', 'Time', 'Status'];
    final colWidths = [
      pw.FlexColumnWidth(2.5),
      pw.FlexColumnWidth(1.5),
      pw.FlexColumnWidth(2),
      pw.FlexColumnWidth(1.5),
      pw.FlexColumnWidth(1.2),
    ];

    return pw.Table(
      columnWidths: {
        for (int i = 0; i < colWidths.length; i++) i: colWidths[i]
      },
      border: pw.TableBorder.all(color: _border, width: 0.5),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _bg),
          children: headers
              .map((h) => _tableCell(h, bold, isHeader: true))
              .toList(),
        ),
        // Data rows
        ...medications.map((m) => pw.TableRow(
              children: [
                _tableCell(m.name, regular),
                _tableCell(m.dosage, regular),
                _tableCell(m.frequency, regular),
                _tableCell(m.time, regular),
                _statusCell(m.status, bold),
              ],
            )),
      ],
    );
  }

  // ── Appointment detail table ───────────────────────────────────────────────

  static pw.Widget _appointmentDetailTable(
    List<AppointmentModel> appointments,
    pw.Font bold,
    pw.Font regular,
  ) {
    final headers = ['Date & Time', 'Title', 'Clinic', 'Doctor', 'Status'];
    final colWidths = [
      pw.FlexColumnWidth(2),
      pw.FlexColumnWidth(2.2),
      pw.FlexColumnWidth(2),
      pw.FlexColumnWidth(1.8),
      pw.FlexColumnWidth(1.2),
    ];

    return pw.Table(
      columnWidths: {
        for (int i = 0; i < colWidths.length; i++) i: colWidths[i]
      },
      border: pw.TableBorder.all(color: _border, width: 0.5),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _bg),
          children: headers
              .map((h) => _tableCell(h, bold, isHeader: true))
              .toList(),
        ),
        // Data rows
        ...appointments.map((a) {
          final status = a.status == 'cancelled'
              ? 'cancelled'
              : a.isPast
                  ? 'past'
                  : 'upcoming';
          return pw.TableRow(
            children: [
              _tableCell(
                  '${a.formattedDateLong}\n${a.formattedTime}', regular,
                  fontSize: 7.5),
              _tableCell(a.title, regular),
              _tableCell(a.clinicName, regular),
              _tableCell(
                  a.doctorName.isNotEmpty ? 'Dr. ${a.doctorName}' : '—',
                  regular),
              _statusCell(status, bold),
            ],
          );
        }),
      ],
    );
  }

  // ── Table cell helpers ─────────────────────────────────────────────────────

  static pw.Widget _tableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    double fontSize = 8.5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 8.5 : fontSize,
          color: isHeader ? _textDark : _textGray,
        ),
      ),
    );
  }

  static pw.Widget _statusCell(String status, pw.Font bold) {
    PdfColor color;
    switch (status) {
      case 'given':
      case 'upcoming':
        color = status == 'given' ? _given : _primary;
        break;
      case 'missed':
      case 'cancelled':
        color = _missed;
        break;
      default:
        color = _pending;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: pw.BoxDecoration(
          color: color.shade(0.15),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Text(
          status.toUpperCase(),
          style: pw.TextStyle(font: bold, fontSize: 7, color: color),
        ),
      ),
    );
  }
}
