import 'package:flutter/material.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../design/app_colors.dart';
import '../application/discover_detail_actions.dart';
import '../domain/county_incident_summary.dart';

class CountyIncidentSummaryPanel extends StatefulWidget {
  const CountyIncidentSummaryPanel({
    super.key,
    required this.countySlug,
    required this.actions,
  });

  final String countySlug;
  final DiscoverDetailActions actions;

  @override
  State<CountyIncidentSummaryPanel> createState() =>
      _CountyIncidentSummaryPanelState();
}

class _CountyIncidentSummaryPanelState
    extends State<CountyIncidentSummaryPanel> {
  late Future<CountyIncidentSummary> _summary = _load();

  Future<CountyIncidentSummary> _load() =>
      widget.actions.countySafetySummary(countySlug: widget.countySlug);

  void _retry() => setState(() => _summary = _load());

  @override
  void didUpdateWidget(covariant CountyIncidentSummaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countySlug != widget.countySlug) _summary = _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CountyIncidentSummary>(
    future: _summary,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _SummaryMessage(
          message: "Couldn't load incident statistics.",
          onRetry: _retry,
        );
      }
      if (!snapshot.hasData) {
        return const _SummaryMessage(message: 'Loading incident statistics…');
      }
      return _SummaryData(summary: snapshot.data!);
    },
  );
}

class _SummaryMessage extends StatelessWidget {
  const _SummaryMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.lockedFill,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(child: Text(message, style: AppTypeScale.small)),
        if (onRetry != null)
          IconButton(
            tooltip: 'Retry incident statistics',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.accent),
          ),
      ],
    ),
  );
}

class _SummaryData extends StatelessWidget {
  const _SummaryData({required this.summary});

  final CountyIncidentSummary summary;

  @override
  Widget build(BuildContext context) {
    final leading = summary.leadingCategories.take(3).toList();
    final highSeverityCount = summary.severities
        .where((item) => {'high', 'critical'}.contains(item.severity))
        .fold<int>(0, (total, item) => total + item.count);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lockedFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reported incidents · last ${summary.periodDays} days',
            style: AppTypeScale.sectionLabel,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${summary.total}', style: AppTypeScale.cardTitle),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(_changeLabel(summary), style: AppTypeScale.small),
                ),
              ),
            ],
          ),
          if (leading.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Most reported: ${leading.map(_categoryLabel).join(' · ')}',
              style: AppTypeScale.body,
            ),
          ],
          if (highSeverityCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$highSeverityCount high/critical reports',
              style: AppTypeScale.small,
            ),
          ],
        ],
      ),
    );
  }
}

String _categoryLabel(CountyIncidentCategoryCount item) {
  final change = item.changePercent;
  final changeLabel = change == null
      ? 'new'
      : '${change > 0 ? '+' : ''}$change%';
  return '${_label(item.category)} (${item.count}, $changeLabel)';
}

String _changeLabel(CountyIncidentSummary summary) {
  if (summary.previousTotal == 0) return '0 reports in previous period';
  final change = summary.changePercent;
  if (change == null || change == 0) return 'No change vs previous period';
  return '${change > 0 ? '+' : ''}$change% vs previous period';
}

String _label(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
