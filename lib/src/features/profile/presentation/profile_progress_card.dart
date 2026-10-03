import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/domain/county_tier.dart';
import '../../../design/app_colors.dart';
import '../../badges/domain/badge_collection.dart';
import '../domain/trip_stats.dart';

class ProfileProgressCard extends StatelessWidget {
  const ProfileProgressCard({
    super.key,
    required this.collection,
    required this.onRetry,
    required this.tripStats,
  });

  final AsyncValue<BadgeCollection> collection;
  final VoidCallback onRetry;
  final AsyncValue<TripStats> tripStats;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: collection.when(
      loading: _loading,
      error: (error, stackTrace) => _error(),
      data: (value) => _progress(value, tripStats),
    ),
  );

  Widget _loading() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Header(trailing: 'COUNTY PROGRESS'),
      SizedBox(height: 10),
      SizedBox(
        height: 42,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 128,
            height: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.trackInactive,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
            ),
          ),
        ),
      ),
      SizedBox(height: 14),
      _Segments(filled: 0, total: 47),
      SizedBox(height: 10),
      Text('Loading your progress...', style: AppTypeScale.meta),
    ],
  );

  Widget _error() => Row(
    children: [
      const Expanded(child: Text('County progress is unavailable right now.')),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  );

  /// "3 more counties to Mzururaji" once a next tier exists, otherwise
  /// the generic count-to-47 caption. Uses the app's real tier names
  /// (`CountyTier`) and counts toward that tier's own threshold, not
  /// toward all 47 -- not the "Explorer · Bronze"-style rank pairing a
  /// recent design reference showed, which isn't a feature that exists
  /// in this codebase yet (tracked separately as "ranks").
  String _caption(BadgeCollection value) {
    if (value.claimed == value.total) return 'You have explored every county.';
    final next = CountyTier.nextAfter(value.claimed);
    if (next == null) {
      return '${value.left} more ${value.left == 1 ? 'county' : 'counties'} to explore';
    }
    final untilNext = next.counties - value.claimed;
    return '$untilNext more ${untilNext == 1 ? 'county' : 'counties'} to ${next.label}';
  }

  Widget _progress(BadgeCollection value, AsyncValue<TripStats> stats) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(trailing: value.tier?.label ?? 'KEEP EXPLORING'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${value.claimed}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 42,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${value.total} counties',
                style: AppTypeScale.sectionTitle.copyWith(
                  fontSize: 15,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Segments(filled: value.claimed, total: value.total),
          const SizedBox(height: 10),
          Text(_caption(value), style: AppTypeScale.meta),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),
          _TripStatsRow(stats: stats),
        ],
      );
}

class _TripStatsRow extends StatelessWidget {
  const _TripStatsRow({required this.stats});

  final AsyncValue<TripStats> stats;

  @override
  Widget build(BuildContext context) {
    final value = stats.value;
    return Row(
      children: [
        Expanded(
          child: _Stat(
            value: value == null ? '—' : '${value.tripCount}',
            label: 'Trips',
          ),
        ),
        const _StatDivider(),
        Expanded(
          child: _Stat(
            value: value == null ? '—' : '${value.totalDistanceKm}',
            unit: 'km',
            label: 'Travelled',
          ),
        ),
        const _StatDivider(),
        Expanded(
          child: _Stat(
            value: value == null ? '—' : '${value.longestDistanceKm}',
            unit: 'km',
            label: 'Longest Trip',
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: SizedBox(
      height: 34,
      child: VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.unit});

  final String value;
  final String? unit;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 2),
            Text(
              unit!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
      Text(label, style: AppTypeScale.statLabel),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.trailing});

  final String trailing;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'KENYA CLAIMED',
        style: TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      Flexible(
        child: Text(
          trailing,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _Segments extends StatelessWidget {
  const _Segments({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 10,
    child: Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: i < filled ? AppColors.accent : AppColors.trackInactive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
