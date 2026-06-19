import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../care_notes/models/care_note_model.dart';
import '../../care_notes/repositories/care_note_repository.dart';

enum _TrendFilter { all, bloodPressure, mood, sleep }

class HealthTrendsScreen extends StatefulWidget {
  final String caregiverId;
  final bool isFamily;

  const HealthTrendsScreen({
    super.key,
    required this.caregiverId,
    this.isFamily = false,
  });

  @override
  State<HealthTrendsScreen> createState() => _HealthTrendsScreenState();
}

class _HealthTrendsScreenState extends State<HealthTrendsScreen> {
  final CareNoteRepository _repository = CareNoteRepository();
  _TrendFilter _selectedFilter = _TrendFilter.all;

  Color get _activeColor =>
      widget.isFamily ? AppColors.purple : AppColors.primary;
  Color get _activeBg =>
      widget.isFamily ? AppColors.purpleBg : AppColors.cyanBg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Trends'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
      ),
      body: StreamBuilder<List<CareNoteModel>>(
        stream: _repository.streamCareNotesForCaregiver(widget.caregiverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load health trends.',
                  style: AppTextStyles.secondary,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notes = snapshot.data ?? [];
          final bpNotes = notes
              .where((note) => note.systolic != null && note.diastolic != null)
              .toList();
          final moodNotes = notes
              .where((note) => note.mood.trim().isNotEmpty)
              .toList();
          final sleepNotes = notes
              .where((note) => note.sleepHours != null)
              .toList();

          if (bpNotes.isEmpty && moodNotes.isEmpty && sleepNotes.isEmpty) {
            return _EmptyTrendsState(
              activeColor: _activeColor,
              activeBg: _activeBg,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _SummaryGrid(
                bpNotes: bpNotes,
                moodNotes: moodNotes,
                sleepNotes: sleepNotes,
                activeColor: _activeColor,
              ),
              const SizedBox(height: 18),
              _FilterTabs(
                selectedFilter: _selectedFilter,
                activeColor: _activeColor,
                activeBg: _activeBg,
                onSelected: (filter) =>
                    setState(() => _selectedFilter = filter),
              ),
              const SizedBox(height: 18),
              if (_selectedFilter == _TrendFilter.all ||
                  _selectedFilter == _TrendFilter.bloodPressure)
                _BloodPressureChartCard(notes: bpNotes),
              if (_selectedFilter == _TrendFilter.all ||
                  _selectedFilter == _TrendFilter.mood)
                _MoodChartCard(notes: moodNotes),
              if (_selectedFilter == _TrendFilter.all ||
                  _selectedFilter == _TrendFilter.sleep)
                _SleepChartCard(notes: sleepNotes),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<CareNoteModel> bpNotes;
  final List<CareNoteModel> moodNotes;
  final List<CareNoteModel> sleepNotes;
  final Color activeColor;

  const _SummaryGrid({
    required this.bpNotes,
    required this.moodNotes,
    required this.sleepNotes,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final latestBp = bpNotes.isEmpty ? '—' : bpNotes.first.bloodPressureText;
    final averageSleep = sleepNotes.isEmpty
        ? '—'
        : '${(sleepNotes.fold<double>(0, (sum, note) => sum + (note.sleepHours ?? 0)) / sleepNotes.length).toStringAsFixed(1)} h';
    final moodPattern = _mostCommonMood(moodNotes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.monitor_heart_outlined,
                label: 'Latest BP',
                value: latestBp,
                color: AppColors.vitalsColor,
                bgColor: AppColors.vitalsBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: Icons.bedtime_outlined,
                label: 'Avg Sleep',
                value: averageSleep,
                color: activeColor,
                bgColor: AppColors.cyanBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: Icons.mood_outlined,
                label: 'Mood',
                value: moodPattern,
                color: AppColors.moodColor,
                bgColor: AppColors.moodBg,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _mostCommonMood(List<CareNoteModel> notes) {
    if (notes.isEmpty) return '—';

    final counts = <String, int>{};
    for (final note in notes) {
      final mood = note.mood.trim();
      if (mood.isEmpty) continue;
      counts[mood] = (counts[mood] ?? 0) + 1;
    }

    if (counts.isEmpty) return '—';

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: bgColor,
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: AppTextStyles.secondarySm),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final _TrendFilter selectedFilter;
  final Color activeColor;
  final Color activeBg;
  final ValueChanged<_TrendFilter> onSelected;

  const _FilterTabs({
    required this.selectedFilter,
    required this.activeColor,
    required this.activeBg,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _TrendFilter.values.map((filter) {
          final selected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              selected: selected,
              showCheckmark: false,
              label: Text(_label(filter)),
              avatar: Icon(
                _icon(filter),
                size: 17,
                color: selected ? activeColor : AppColors.textSecondary,
              ),
              selectedColor: activeBg,
              backgroundColor: AppColors.card,
              side: BorderSide(
                color: selected ? activeColor : AppColors.border,
              ),
              labelStyle: AppTextStyles.bodySm.copyWith(
                color: selected ? activeColor : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
              onSelected: (_) => onSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(_TrendFilter filter) {
    switch (filter) {
      case _TrendFilter.all:
        return 'All';
      case _TrendFilter.bloodPressure:
        return 'Blood Pressure';
      case _TrendFilter.mood:
        return 'Mood';
      case _TrendFilter.sleep:
        return 'Sleep';
    }
  }

  IconData _icon(_TrendFilter filter) {
    switch (filter) {
      case _TrendFilter.all:
        return Icons.auto_graph_outlined;
      case _TrendFilter.bloodPressure:
        return Icons.monitor_heart_outlined;
      case _TrendFilter.mood:
        return Icons.mood_outlined;
      case _TrendFilter.sleep:
        return Icons.bedtime_outlined;
    }
  }
}

class _BloodPressureChartCard extends StatelessWidget {
  final List<CareNoteModel> notes;

  const _BloodPressureChartCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final chartNotes = _oldestFirst(notes);

    return _ChartCard(
      title: 'Blood Pressure Trend',
      subtitle: 'Systolic and diastolic readings from care notes',
      icon: Icons.monitor_heart_outlined,
      iconColor: AppColors.vitalsColor,
      iconBg: AppColors.vitalsBg,
      emptyText: 'No blood pressure readings yet.',
      hasData: chartNotes.isNotEmpty,
      footer: const _LegendRow(
        items: [
          _LegendItem(label: 'Systolic', color: AppColors.vitalsColor),
          _LegendItem(label: 'Diastolic', color: AppColors.primary),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: 40,
          maxY: _bpMax(chartNotes),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.borderLight, strokeWidth: 1),
          ),
          titlesData: _titles(chartNotes),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: true),
          lineBarsData: [
            LineChartBarData(
              spots: _spots(chartNotes, (note) => note.systolic?.toDouble()),
              color: AppColors.vitalsColor,
              barWidth: 3,
              isCurved: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.vitalsColor.withOpacity(0.08),
              ),
            ),
            LineChartBarData(
              spots: _spots(chartNotes, (note) => note.diastolic?.toDouble()),
              color: AppColors.primary,
              barWidth: 3,
              isCurved: true,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  double _bpMax(List<CareNoteModel> notes) {
    final values = <int>[
      for (final note in notes)
        if (note.systolic != null) note.systolic!,
      for (final note in notes)
        if (note.diastolic != null) note.diastolic!,
    ];
    if (values.isEmpty) return 200;
    final max = values.reduce((a, b) => a > b ? a : b).toDouble() + 20;
    return max < 160 ? 160 : max;
  }
}

class _MoodChartCard extends StatelessWidget {
  final List<CareNoteModel> notes;

  const _MoodChartCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final chartNotes = _oldestFirst(notes);

    return _ChartCard(
      title: 'Mood Trend',
      subtitle: 'Mood pattern scored from concerning to positive',
      icon: Icons.mood_outlined,
      iconColor: AppColors.moodColor,
      iconBg: AppColors.moodBg,
      emptyText: 'No mood entries yet.',
      hasData: chartNotes.isNotEmpty,
      footer: Text(
        'Higher bars indicate calmer or happier mood entries.',
        style: AppTextStyles.secondarySm,
      ),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.borderLight, strokeWidth: 1),
          ),
          titlesData: _titles(chartNotes),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: true),
          barGroups: [
            for (var i = 0; i < chartNotes.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: _moodScore(chartNotes[i].mood),
                    width: 16,
                    borderRadius: BorderRadius.circular(6),
                    color: _moodColor(chartNotes[i].mood),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SleepChartCard extends StatelessWidget {
  final List<CareNoteModel> notes;

  const _SleepChartCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final chartNotes = _oldestFirst(notes);

    return _ChartCard(
      title: 'Sleep Hours Trend',
      subtitle: 'Recorded hours of sleep across care notes',
      icon: Icons.bedtime_outlined,
      iconColor: AppColors.primary,
      iconBg: AppColors.cyanBg,
      emptyText: 'No sleep records yet.',
      hasData: chartNotes.isNotEmpty,
      footer: Text(
        'Less than 4 hours is treated as an abnormal pattern.',
        style: AppTextStyles.secondarySm,
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: _sleepMax(chartNotes),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.borderLight, strokeWidth: 1),
          ),
          titlesData: _titles(chartNotes),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: true),
          lineBarsData: [
            LineChartBarData(
              spots: _spots(chartNotes, (note) => note.sleepHours),
              color: AppColors.primary,
              barWidth: 3,
              isCurved: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _sleepMax(List<CareNoteModel> notes) {
    final values = notes
        .map((note) => note.sleepHours)
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 10;
    final max = values.reduce((a, b) => a > b ? a : b) + 2;
    return max < 10 ? 10 : max;
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String emptyText;
  final bool hasData;
  final Widget child;
  final Widget? footer;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.emptyText,
    required this.hasData,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: iconBg,
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.h4),
                    Text(subtitle, style: AppTextStyles.secondarySm),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (hasData)
            SizedBox(height: 220, child: child)
          else
            _InlineEmptyState(text: emptyText),
          if (hasData && footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final List<_LegendItem> items;

  const _LegendRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 14, runSpacing: 8, children: items);
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.secondarySm),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String text;

  const _InlineEmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        text,
        style: AppTextStyles.secondarySm,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EmptyTrendsState extends StatelessWidget {
  final Color activeColor;
  final Color activeBg;

  const _EmptyTrendsState({required this.activeColor, required this.activeBg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: activeBg,
              child: Icon(
                Icons.auto_graph_outlined,
                color: activeColor,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No health trends yet',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add care notes with blood pressure, mood, or sleep details to see visual trends here.',
              style: AppTextStyles.secondarySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

List<CareNoteModel> _oldestFirst(List<CareNoteModel> notes) {
  final sorted = [...notes]..sort((a, b) => a.date.compareTo(b.date));
  if (sorted.length <= 10) return sorted;
  return sorted.sublist(sorted.length - 10);
}

List<FlSpot> _spots(
  List<CareNoteModel> notes,
  double? Function(CareNoteModel note) valueFor,
) {
  final spots = <FlSpot>[];
  for (var i = 0; i < notes.length; i++) {
    final value = valueFor(notes[i]);
    if (value != null) spots.add(FlSpot(i.toDouble(), value));
  }
  return spots;
}

FlTitlesData _titles(List<CareNoteModel> notes) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 34,
        getTitlesWidget: (value, meta) {
          return Text(
            value.round().toString(),
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 34,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= notes.length) {
            return const SizedBox.shrink();
          }
          final note = notes[index];
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${note.date.day}/${note.date.month}',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          );
        },
      ),
    ),
  );
}

double _moodScore(String mood) {
  switch (mood.toLowerCase().trim()) {
    case 'happy':
      return 5;
    case 'calm':
      return 4;
    case 'unwell':
      return 2;
    case 'anxious':
    case 'sad':
    case 'irritable':
      return 1;
    default:
      return 3;
  }
}

Color _moodColor(String mood) {
  final score = _moodScore(mood);
  if (score >= 4) return AppColors.given;
  if (score <= 2) return AppColors.alertAmber;
  return AppColors.moodColor;
}
