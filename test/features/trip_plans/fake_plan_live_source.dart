import 'dart:async';

import 'package:kaunti47_v2/src/features/trip_plans/data/plan_live_source.dart';

/// A [PlanLiveSource] for tests: call [emit] to say the plan changed.
class FakePlanLiveSource implements PlanLiveSource {
  final _controller = StreamController<void>.broadcast();

  void emit() => _controller.add(null);

  @override
  Stream<void> changes(String planId) => _controller.stream;
}
