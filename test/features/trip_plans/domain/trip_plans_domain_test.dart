import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_counties.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_failure.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_labels.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_limits.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/plan_member.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/planned_trips.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan.dart';
import 'package:kaunti47_v2/src/features/trip_plans/domain/trip_plan_summary.dart';

TripPlanSummary _plan(
  String id, {
  PlanRole role = PlanRole.owner,
  DateTime? start,
  bool past = false,
  bool archived = false,
  bool converted = false,
  DateTime? updated,
}) => TripPlanSummary(
  id: id,
  title: id,
  ownerId: role == PlanRole.owner ? 'me' : 'them',
  role: role,
  startDate: start,
  isPast: past,
  archived: archived,
  converted: converted,
  updatedAt: updated ?? DateTime(2026, 10, 1),
);

void main() {
  group('PlanLimits', () {
    test('reads Free and Pro from the server', () {
      final free = PlanLimits.fromJson({
        'pro': false,
        'max_upcoming_plans': 3,
        'max_days': 3,
        'max_stops_per_day': 8,
        'max_places': 30,
        'max_members': 2,
        'upcoming_plans': 3,
      });
      expect(free.canCreatePlan, isFalse);
      expect(free.canAddDay(2), isTrue);
      expect(free.canAddDay(3), isFalse);
      expect(free.isDayLocked(4), isTrue);
      expect(free.isStopLocked(8), isTrue);
      expect(free.isStopLocked(7), isFalse);

      final pro = PlanLimits.fromJson({
        'pro': true,
        'max_upcoming_plans': null,
        'max_days': 14,
        'max_stops_per_day': 20,
        'upcoming_plans': 12,
      });
      expect(pro.canCreatePlan, isTrue);
      expect(pro.maxDays, 14);
    });

    test('falls back to Free when the answer is missing', () {
      expect(PlanLimits.fromJson(null).maxDays, 3);
      expect(PlanLimits.fromJson('nonsense').pro, isFalse);
    });
  });

  group('PlannedTrips.split', () {
    test('dated plans first, soonest first, then undated by last change', () {
      final split = PlannedTrips.split([
        _plan('undated-old', updated: DateTime(2026, 9, 1)),
        _plan('dec', start: DateTime(2026, 12, 11)),
        _plan('nov', start: DateTime(2026, 11, 14)),
        _plan('undated-new', updated: DateTime(2026, 10, 20)),
      ]);
      expect(split.upcoming.map((p) => p.id), [
        'nov',
        'dec',
        'undated-new',
        'undated-old',
      ]);
    });

    test('shared, past and archived go to their own sections', () {
      final split = PlannedTrips.split([
        _plan('mine'),
        _plan('theirs', role: PlanRole.editor),
        _plan('done', past: true),
        _plan('put-away', archived: true),
      ]);
      expect(split.upcoming.single.id, 'mine');
      expect(split.shared.single.id, 'theirs');
      expect(split.past.single.id, 'done');
      expect(split.archived.single.id, 'put-away');
    });

    test('converted plans never count toward the Free limit', () {
      final split = PlannedTrips.split([
        _plan('a'),
        _plan('old', converted: true),
      ]);
      expect(split.upcoming, hasLength(2));
      expect(split.countedUpcoming, 1);
    });
  });

  group('defaultTripsSegment', () {
    test('recording wins, then upcoming plans, else Recorded', () {
      expect(
        defaultTripsSegment(recording: true, hasUpcomingPlan: true),
        TripsSegment.recorded,
      );
      expect(
        defaultTripsSegment(recording: false, hasUpcomingPlan: true),
        TripsSegment.planned,
      );
      expect(
        defaultTripsSegment(recording: false, hasUpcomingPlan: false),
        TripsSegment.recorded,
      );
    });
  });

  group('PlanCounties', () {
    test('marks home, claimed and new, once each', () {
      final counties = PlanCounties.of(
        [47, 22, 32, 22],
        claimed: {22},
        homeCode: 47,
      );
      expect(counties.map((c) => c.code), [47, 22, 32]);
      expect(counties.map((c) => c.status), [
        PlanCountyStatus.home,
        PlanCountyStatus.claimed,
        PlanCountyStatus.notClaimed,
      ]);
    });

    test('a county new on two days counts once for the plan', () {
      final count = PlanCounties.newCount(
        [
          [47, 22, 32],
          [32, 18, 31],
        ],
        claimed: {22},
        homeCode: 47,
      );
      expect(count, 3);
    });
  });

  group('PlanLabels', () {
    test('dates', () {
      expect(PlanLabels.day(DateTime(2026, 11, 14)), 'Sat 14 Nov');
      expect(
        PlanLabels.range(DateTime(2026, 11, 14), DateTime(2026, 11, 15)),
        '14 – 15 Nov',
      );
      expect(
        PlanLabels.range(DateTime(2026, 11, 30), DateTime(2026, 12, 2)),
        '30 Nov – 2 Dec',
      );
      expect(PlanLabels.range(null, null), 'No date yet');
      expect(
        PlanLabels.longRange(DateTime(2026, 11, 14), DateTime(2026, 11, 15)),
        'Sat 14 – Sun 15 Nov',
      );
    });

    test('drive times are estimates', () {
      expect(PlanLabels.drive(70 * 60), 'about 1 h 10 min');
      expect(PlanLabels.drive(45 * 60), 'about 45 min');
      expect(PlanLabels.drive(120 * 60), 'about 2 h');
      expect(PlanLabels.distance(62400), '62 km');
      expect(PlanLabels.counties(5, 3), 'Passes through 5 counties · 3 new');
      expect(PlanLabels.counties(1, 0), 'Passes through 1 county');
      expect(PlanLabels.counties(0, 0), isNull);
    });
  });

  group('TripPlan', () {
    test('round-trips through the copy kept on the phone', () {
      final json = {
        'id': 'p1',
        'title': 'Naivasha & Nakuru weekend',
        'owner_id': 'me',
        'role': 'owner',
        'start_kind': 'point',
        'start_label': 'Westlands, Nairobi',
        'start_lat': -1.26,
        'start_lng': 36.8,
        'start_date': '2026-11-14',
        'limits': {'pro': false, 'max_days': 3},
        'days': [
          {'id': 'd2', 'position': 2, 'stops': <Object>[]},
          {
            'id': 'd1',
            'position': 1,
            'title': 'Rift Valley drive',
            'stops': [
              {
                'id': 's1',
                'note': 'Quick stop, 20 min',
                'place': {
                  'id': 'pl1',
                  'name': 'Rift Valley Viewpoint',
                  'type': 'viewpoint',
                  'county_code': 22,
                  'lat': -1.0,
                  'lng': 36.6,
                },
              },
            ],
            'route_stops_key': 's1',
            'distance_m': 62000,
            'duration_s': 4200,
            'county_codes': [47, 22],
          },
        ],
        'places': <Object>[],
        'members': [
          {'user_id': 'me', 'role': 'owner', 'handle': 'amina7'},
        ],
      };
      final plan = TripPlan.fromJson(json)!;
      expect(plan.days.map((d) => d.number), [1, 2]);
      expect(plan.days.first.hasFreshRoute, isTrue);
      expect(plan.days.last.displayTitle, 'Day 2');
      expect(plan.endDate, DateTime(2026, 11, 15));
      expect(plan.start.displayLabel, 'Westlands, Nairobi');

      final copy = TripPlan.fromJson(plan.toJson())!;
      expect(copy.title, plan.title);
      expect(copy.days.first.stops.single.place.name, 'Rift Valley Viewpoint');
      expect(copy.startDate, plan.startDate);
    });
  });

  test('server codes map to failures', () {
    expect(
      PlanFailureKind.fromCode('trip_plan_limit_days'),
      PlanFailureKind.limitDays,
    );
    expect(PlanFailureKind.fromCode('trip_plan_limit_days').isLimit, isTrue);
    expect(PlanFailureKind.fromCode('something else'), PlanFailureKind.unknown);
  });
}
