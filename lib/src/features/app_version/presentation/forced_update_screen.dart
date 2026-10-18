import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_provider.dart';
import '../../../design/app_colors.dart';
import '../application/app_update_providers.dart';
import '../domain/app_update_policy.dart';
import '../domain/update_notes.dart';
import 'forced_update_footer.dart';
import 'update_copy.dart';
import 'update_notes_list.dart';
import 'update_widgets.dart';

enum UpdateProblem { none, offline, storeFailed }

/// Blocking update screen. It is the root route while an update is required:
/// no close, no back, and coming back from the store without updating shows
/// the same screen unchanged.
class ForcedUpdateScreen extends ConsumerStatefulWidget {
  const ForcedUpdateScreen({super.key});

  @override
  ConsumerState<ForcedUpdateScreen> createState() => _ForcedUpdateScreenState();
}

class _ForcedUpdateScreenState extends ConsumerState<ForcedUpdateScreen>
    with WidgetsBindingObserver {
  bool _expanded = false;
  bool _busy = false;
  bool _stillNoLink = false;
  UpdateProblem _problem = UpdateProblem.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appUpdateControllerProvider.notifier).check());
    }
  }

  Future<void> _primary(AppUpdatePolicy policy) async {
    final controller = ref.read(appUpdateControllerProvider.notifier);
    setState(() {
      _busy = true;
      _problem = UpdateProblem.none;
    });
    if (policy.storeUrl == null) {
      final reachable = await controller.recheck();
      if (!mounted) return;
      final stillMissing =
          ref.read(appUpdateControllerProvider)?.storeUrl == null;
      setState(() {
        _busy = false;
        _problem = reachable ? UpdateProblem.none : UpdateProblem.offline;
        _stillNoLink = reachable && stillMissing;
      });
      return;
    }
    if (ref.read(connectivityProvider).isOffline) {
      setState(() {
        _busy = false;
        _problem = UpdateProblem.offline;
      });
      return;
    }
    final opened = await controller.openStore();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problem = opened ? UpdateProblem.none : UpdateProblem.storeFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(appUpdateControllerProvider);
    if (policy == null) {
      return const Scaffold(backgroundColor: AppColors.pageBackground);
    }
    final notes = parseUpdateNotes(policy.releaseNotes);
    final long = notes.fold<int>(0, (n, l) => n + (l.length / 40).ceil()) > 10;
    final version = policy.latestVersion ?? policy.requiredVersion;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 250),
          builder: (context, t, child) => Opacity(opacity: t, child: child),
          child: Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          child: _Content(
                            version: version,
                            notes: notes,
                            long: long,
                            expanded: _expanded,
                            onToggle: () =>
                                setState(() => _expanded = !_expanded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ForcedUpdateFooter(
                policy: policy,
                busy: _busy,
                problem: _problem,
                stillNoLink: _stillNoLink,
                raised: _expanded,
                onPrimary: () => unawaited(_primary(policy)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.version,
    required this.notes,
    required this.long,
    required this.expanded,
    required this.onToggle,
  });

  final Object? version;
  final List<String> notes;
  final bool long;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: notes.isEmpty
        ? MainAxisAlignment.center
        : MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 16),
      const UpdateAppIcon(size: 88, halo: true),
      const SizedBox(height: 16),
      const Text(
        'Time to update Kaunti47',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          height: 1.2,
          letterSpacing: -0.48,
          fontWeight: FontWeight.w700,
          color: AppColors.buttonForeground,
        ),
      ),
      const SizedBox(height: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: const Text(
          'This version includes changes the app needs to keep working.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.bodyText),
        ),
      ),
      if (version != null) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            updateVersionLabel(version!),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.buttonForeground,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
      if (notes.isNotEmpty) ...[
        const SizedBox(height: 28),
        _NotesCard(
          notes: notes,
          long: long,
          expanded: expanded,
          onToggle: onToggle,
        ),
      ],
    ],
  );
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.notes,
    required this.long,
    required this.expanded,
    required this.onToggle,
  });

  final List<String> notes;
  final bool long;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's new",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.buttonForeground,
          ),
        ),
        const SizedBox(height: 12),
        UpdateNotesList(
          items: notes,
          collapsedHeight: long && !expanded ? 195 : null,
        ),
        if (long)
          UpdateNotesToggle(
            expanded: expanded,
            moreLabel: 'Show all',
            lessLabel: 'Show less',
            onTap: onToggle,
          )
        else
          const SizedBox(height: 12),
      ],
    ),
  );
}
