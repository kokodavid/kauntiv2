import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/app_logger.dart';
import '../domain/county_badge_detail.dart';

typedef CountyStayHistory = ({
  int timedVisits,
  int longVisits,
  Duration total,
  List<CountyStay> recent,
});

const _empty = (
  timedVisits: 0,
  longVisits: 0,
  total: Duration.zero,
  recent: <CountyStay>[],
);

/// One county's stays (`county_stay_summary`). Best effort: without it the
/// county page just has no total, rather than failing.
Future<CountyStayHistory> fetchCountyStayHistory(
  SupabaseClient client,
  int countyCode,
) async {
  try {
    final row = await client
        .rpc<Map<String, dynamic>>(
          'county_stay_summary',
          params: {'p_county_id': countyCode},
        )
        .timeout(const Duration(seconds: 8));
    return (
      timedVisits: (row['timed_visits'] as num?)?.toInt() ?? 0,
      longVisits: (row['long_visits'] as num?)?.toInt() ?? 0,
      total: Duration(
        seconds: (row['total_stay_seconds'] as num?)?.toInt() ?? 0,
      ),
      recent: [
        for (final stay
            in (row['recent'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>())
          if (stay case {
            'entered_at': final String enteredAt,
            'outcome': final String outcome,
          })
            if (DateTime.tryParse(enteredAt) case final at?)
              CountyStay(
                enteredAt: at,
                explored: outcome == 'explored',
                stay: switch (stay['stay_seconds']) {
                  final num seconds => Duration(seconds: seconds.toInt()),
                  _ => null,
                },
              ),
      ],
    );
  } on Object catch (error, stackTrace) {
    const AppLogger.badges().warning(
      'County stay times unavailable.',
      error: error,
      stackTrace: stackTrace,
    );
    return _empty;
  }
}
