import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/app_colors.dart';
import '../application/plan_collapsed_days.dart';
import '../application/plan_detail.dart';
import '../application/plan_route_saver.dart';
import '../application/plan_routing_providers.dart';
import '../application/trip_plans_providers.dart';
import '../domain/plan_day.dart';
import '../domain/plan_day_path.dart';
import '../domain/plan_member.dart';
import '../domain/plan_route.dart';
import '../domain/plan_totals.dart';
import 'plan_day_chips.dart';
import 'plan_day_section.dart';
import 'plan_header.dart';
import 'plan_map_panel.dart';
import 'plan_menu.dart';
import 'plan_places_row.dart';
import 'plan_screen_actions.dart';
import 'plan_screen_states.dart';
import 'plan_stop_row.dart';
import 'plan_totals_bar.dart';

/// A trip plan (design 3a to 3c), read side: header, map, totals, day
/// chips, the days with their stops and roads, and Places to visit. Shows
/// the copy on this phone first and keeps working offline (read-only).
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({
    super.key,
    required this.planId,
    required this.onBack,
    this.homeCountyCode,
    this.onOpenPlace,
  });

  final String planId;
  final VoidCallback onBack;
  final int? homeCountyCode;
  final OpenPlanPlace? onOpenPlace;

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int? _activeDay;
  bool _mapOpen = true;
  final _dayKeys = <int, GlobalKey>{};

  void _selectDay(int? day) {
    setState(() => _activeDay = day);
    final context = day == null ? null : _dayKeys[day]?.currentContext;
    if (context != null) {
      unawaited(
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          alignment: 0.12,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(planDetailProvider(widget.planId));
    final view = detail.value;
    final Widget body;
    if (view != null) {
      body = _loaded(view);
    } else if (detail.hasError) {
      body = PlanScreenProblem(
        error: detail.error!,
        onRetry: () => ref.invalidate(planDetailProvider(widget.planId)),
        onBack: widget.onBack,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Back',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          const PlanScreenSkeleton(),
        ],
      );
    }
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(bottom: false, child: body),
    );
  }

  Widget _loaded(PlanDetailView view) {
    final plan = view.plan;
    final claimed =
        ref.watch(planClaimedCountyCodesProvider).value ?? const <int>{};
    final saver = ref.read(planRouteSaverProvider);
    // Changes need a connection (offline copies are read only) and a role
    // that may edit.
    final actions = plan.canEdit && !view.offline
        ? PlanScreenActions(context, ref, plan, onGone: widget.onBack)
        : null;

    final requests = <int, PlanLegRequest>{};
    final legs = <int, AsyncValue<PlanRoute?>>{};
    for (final day in plan.days) {
      final request = PlanLegRequest(PlanDayPath.waypoints(plan, day));
      requests[day.number] = request;
      final leg = ref.watch(planDayRouteProvider(request));
      legs[day.number] = leg;
      final worked = leg.value;
      if (worked != null && !view.offline && !day.hasFreshRoute) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(saver.save(day, worked)),
        );
      }
    }
    final mapDays = [
      for (final day in plan.days)
        PlanMapDay(
          number: day.number,
          line:
              legs[day.number]?.value?.points ??
              PlanDayPath.waypoints(plan, day),
          stops: PlanDayPath.stopPoints(day),
          estimated: legs[day.number]?.value == null,
        ),
    ];
    final totals = PlanTotals.of(
      plan.days,
      routes: {
        for (final entry in legs.entries)
          if (entry.value.value case final route?)
            entry.key: (distanceM: route.distanceM, durationS: route.durationS),
      },
    );

    final stored = ref.watch(planCollapsedDaysProvider(plan.id)).value;
    final collapsed = stored ?? PlanCollapsedDays.defaultFor(plan.days.length);

    return RefreshIndicator(
      onRefresh: () => ref.read(planDetailProvider(plan.id).notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PlanHeader(
              plan: plan,
              onBack: widget.onBack,
              offline: view.offline,
              savedAt: view.savedAt,
              menu: actions == null
                  ? null
                  : PlanMenu(
                      isOwner: plan.role == PlanRole.owner,
                      onSelected: (a) => unawaited(actions.planMenu(a)),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: PlanMapPanel(
              days: mapDays,
              activeDay: _activeDay,
              open: _mapOpen,
              onToggle: () => setState(() => _mapOpen = !_mapOpen),
            ),
          ),
          SliverToBoxAdapter(
            child: PlanTotalsBar(
              totals: totals,
              claimed: claimed,
              homeCode: widget.homeCountyCode,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: PlanDayChipsDelegate(
              dayNumbers: [for (final d in plan.days) d.number],
              active: _activeDay,
              onSelect: _selectDay,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              for (final PlanDay day in plan.days)
                KeyedSubtree(
                  key: _dayKeys.putIfAbsent(day.number, GlobalKey.new),
                  child: PlanDaySection(
                    plan: plan,
                    day: day,
                    route: legs[day.number]!,
                    collapsed: collapsed.contains(day.number),
                    onToggle: () => unawaited(
                      ref
                          .read(planCollapsedDaysProvider(plan.id).notifier)
                          .toggle(day.number, current: collapsed),
                    ),
                    onRetryRoute: () => ref.invalidate(
                      planDayRouteProvider(requests[day.number]!),
                    ),
                    claimed: claimed,
                    homeCode: widget.homeCountyCode,
                    onOpenPlace: widget.onOpenPlace,
                    actions: actions?.forDay(day),
                  ),
                ),
              if (actions != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => unawaited(actions.addDay()),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a day'),
                  ),
                ),
            ]),
          ),
          SliverToBoxAdapter(
            child: PlanPlacesRow(
              ideas: plan.places,
              maxPlaces: plan.limits.maxPlaces,
              onAdd: actions == null
                  ? null
                  : () => unawaited(actions.addPlaces()),
              onOpenPlace: widget.onOpenPlace,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
