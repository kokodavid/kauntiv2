import 'package:flutter/material.dart';

import '../../../core/widgets/app_shimmer.dart';

/// Profile's Trips / Travelled / Longest Trip row while it loads: the same
/// shimmer the county badge sheet uses, in the shape of three stats.
class ProfileStatsSkeleton extends StatelessWidget {
  const ProfileStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const AppShimmer(
    child: Row(
      children: [
        Expanded(child: _Stat()),
        _Divider(),
        Expanded(child: _Stat()),
        _Divider(),
        Expanded(child: _Stat()),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppSkeleton(width: 34, height: 17),
      SizedBox(height: 5),
      AppSkeleton(width: 54, height: 10),
    ],
  );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4),
    child: SizedBox(
      height: 34,
      child: VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
    ),
  );
}
