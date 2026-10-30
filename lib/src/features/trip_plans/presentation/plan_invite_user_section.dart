import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../../../design/app_colors.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../application/plan_sharing.dart';
import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_edit_sheets.dart';
import 'plan_share_parts.dart';
import 'plan_sheet_frame.dart';

/// Find a person by username (3 letters or more) and invite them. They get
/// an invitation to accept; nothing about them shows but username and photo.
class PlanInviteUserSection extends ConsumerStatefulWidget {
  const PlanInviteUserSection({
    super.key,
    required this.plan,
    required this.role,
  });

  final TripPlan plan;
  final PlanRole role;

  @override
  ConsumerState<PlanInviteUserSection> createState() => _State();
}

class _State extends ConsumerState<PlanInviteUserSection> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _invite(UsernameHit hit) async {
    final failure = await ref
        .read(planSharingProvider)
        .inviteUser(widget.plan.id, hit.handle, widget.role);
    if (!mounted) return;
    if (failure != null) {
      reportPlanFailure(context, failure);
      return;
    }
    _controller.clear();
    setState(() => _query = '');
    showAppToast(
      context,
      variant: AppToastVariant.success,
      title: 'Invited ${hit.handle}',
    );
  }

  /// "Already in this plan" or "Invited", else null.
  String? _status(String handle) {
    for (final m in widget.plan.members) {
      if (m.handle == handle) return m.joined ? 'Already in this plan' : 'Invited';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hits = _query.length < 3
        ? null
        : ref.watch(usernameSearchProvider(_query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PlanShareLabel('Invite by username'),
        TextField(
          controller: _controller,
          onChanged: _changed,
          autocorrect: false,
          style: AppTypeScale.itemTitle.copyWith(fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            hintText: 'Type at least 3 letters',
            hintStyle: AppTypeScale.itemTitle.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.faintForeground,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Text(
                '@',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: AppColors.faintForeground,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: _border(AppColors.inputBorder),
            enabledBorder: _border(AppColors.inputBorder),
            focusedBorder: _border(AppColors.accent, width: 1.5),
          ),
        ),
        if (hits != null)
          hits.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: AppProgressIndicator()),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "Couldn't search right now.",
                style: AppTypeScale.small,
              ),
            ),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('No one found.', style: AppTypeScale.small),
                  )
                : Column(
                    children: [
                      for (final (i, hit) in list.indexed)
                        _PersonRow(
                          hit: hit,
                          status: _status(hit.handle),
                          last: i == list.length - 1,
                          onInvite: () => unawaited(_invite(hit)),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.hit,
    required this.status,
    required this.last,
    required this.onInvite,
  });

  final UsernameHit hit;
  final String? status;
  final bool last;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: status == null ? 1 : 0.55,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.exploreBorder)),
      ),
      child: Row(
        children: [
          PlanPersonAvatar(
            initial: hit.handle.substring(0, 1).toUpperCase(),
            url: hit.avatarUrl,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hit.handle,
                  style: AppTypeScale.itemTitle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (status != null) Text(status!, style: AppTypeScale.small),
              ],
            ),
          ),
          if (status == null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                backgroundColor: AppColors.accentTint,
                textStyle: AppTypeScale.action.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                minimumSize: const Size(72, 40),
                shape: const StadiumBorder(),
              ),
              onPressed: onInvite,
              child: const Text('Invite'),
            ),
        ],
      ),
    ),
  );
}
