import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_type_scale.dart';
import '../../../core/widgets/app_floating_toast.dart';
import '../application/plan_sharing.dart';
import '../domain/plan_invite.dart';
import '../domain/plan_member.dart';
import '../domain/trip_plan.dart';
import 'plan_edit_sheets.dart';
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

  @override
  Widget build(BuildContext context) {
    final hits = _query.length < 3
        ? null
        : ref.watch(usernameSearchProvider(_query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Or invite by username', style: AppTypeScale.sectionLabel),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          onChanged: _changed,
          autocorrect: false,
          decoration: const InputDecoration(
            hintText: 'Type at least 3 letters',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        if (hits != null)
          hits.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                      for (final hit in list)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: PlanPersonAvatar(
                            initial: hit.handle.substring(0, 1).toUpperCase(),
                            url: hit.avatarUrl,
                          ),
                          title: Text(hit.handle),
                          trailing: FilledButton.tonal(
                            onPressed: () => unawaited(_invite(hit)),
                            child: const Text('Invite'),
                          ),
                        ),
                    ],
                  ),
          ),
      ],
    );
  }
}
