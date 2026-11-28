import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../counties/county_paths.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_text_styles.dart';
import '../../detection/application/detection_controller.dart';
import '../../detection/domain/pending_claim.dart';
import '../../detection/domain/visit_rules.dart';

/// "Kisumu: claims in 1 h 20 m" while a county visit is pending, so a
/// tester who has just arrived can see the claim is on its way. Rides
/// above the bottom sheet beside the location pill; nothing shows when no
/// visit is pending.
class MapHomePendingClaimPill extends ConsumerStatefulWidget {
  const MapHomePendingClaimPill({
    super.key,
    this.claimedCountyCodes = const {},
  });

  /// Counties the user has already earned; they never show a countdown.
  final Set<int> claimedCountyCodes;

  @override
  ConsumerState<MapHomePendingClaimPill> createState() => _State();
}

class _State extends ConsumerState<MapHomePendingClaimPill> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 30),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidates = ref.watch(
      detectionControllerProvider.select((s) => s.activeCandidates),
    );
    final claim = PendingClaim.soonest(
      candidates,
      VisitTimings.current.dwellThreshold,
      claimed: widget.claimedCountyCodes,
    );
    final county = claim == null ? null : CountyPaths.byCode[claim.countyCode];
    if (claim == null || county == null) return const SizedBox.shrink();
    final left = PendingClaim.timeLeft(claim.remaining(DateTime.now()));
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        label: '${county.name} claims in $left',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: StadiumBorder(
              side: BorderSide(color: AppColors.green.withValues(alpha: .35)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 15,
                  color: AppColors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  '${county.name}: claims in $left',
                  style: AppTextStyles.listItemTitle.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
