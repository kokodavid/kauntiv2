import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Tells the app when something in an open plan changed on the server.
/// Only a nudge: the plan is then read again, so a missed or repeated
/// event does no harm.
abstract interface class PlanLiveSource {
  Stream<void> changes(String planId);
}

/// Supabase Realtime over the plan's tables (RLS applies, so only members
/// receive anything).
class SupabasePlanLiveSource implements PlanLiveSource {
  const SupabasePlanLiveSource(this.client);

  final SupabaseClient client;

  static const _byPlan = [
    'trip_plan_days',
    'trip_plan_stops',
    'trip_plan_places',
    'trip_plan_members',
  ];

  @override
  Stream<void> changes(String planId) {
    late final StreamController<void> controller;
    RealtimeChannel? channel;
    controller = StreamController<void>(
      onListen: () {
        void nudge(Object? _) {
          if (!controller.isClosed) controller.add(null);
        }

        PostgresChangeFilter filter(String column) => PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: column,
          value: planId,
        );
        var next = client.channel('trip-plan-$planId');
        for (final table in _byPlan) {
          next = next.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: filter('plan_id'),
            callback: nudge,
          );
        }
        next = next.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trip_plans',
          filter: filter('id'),
          callback: nudge,
        );
        channel = next..subscribe();
      },
      onCancel: () {
        final open = channel;
        if (open != null) unawaited(client.removeChannel(open));
        unawaited(controller.close());
      },
    );
    return controller.stream;
  }
}
