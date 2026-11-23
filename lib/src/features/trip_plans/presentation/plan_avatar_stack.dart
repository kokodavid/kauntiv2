import 'package:flutter/material.dart';

import '../../../core/widgets/app_network_image.dart';
import '../../../design/app_colors.dart';
import '../domain/plan_member.dart';

/// Overlapping member avatars (photo, or the username's first letter).
/// Usernames only; never a real name.
class PlanAvatarStack extends StatelessWidget {
  const PlanAvatarStack({
    super.key,
    required this.members,
    this.size = 24,
    this.max = 4,
  });

  final List<PlanMember> members;
  final double size;
  final int max;

  static const _fills = [
    AppColors.planDay1,
    AppColors.planDay4,
    AppColors.planDay3,
    AppColors.planDay2,
    AppColors.planDay5,
    AppColors.planDay6,
  ];

  @override
  Widget build(BuildContext context) {
    final shown = members.take(max).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final overlap = size * 0.3;
    return SizedBox(
      height: size,
      width: size + (shown.length - 1) * (size - overlap),
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: _Avatar(
                member: shown[i],
                size: size,
                fill: _fills[i % _fills.length],
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member, required this.size, required this.fill});

  final PlanMember member;
  final double size;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final url = member.avatarUrl;
    return Semantics(
      label: member.handle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: Colors.white, width: 2),
          image: url == null
              ? null
              : DecorationImage(
                  image: appNetworkImage(url, cacheWidth: 96),
                  fit: BoxFit.cover,
                  onError: (_, _) {},
                ),
        ),
        alignment: Alignment.center,
        child: url == null
            ? Text(
                member.initial,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}
