import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../widgets/app_toast.dart';

/// v2 location-permission screen (Figma "Location Permission" node
/// 235:6794 default state / 235:6850 permission-denied state, with its
/// "Toast" banner at node 235:6904). Full rewrite of the v1 screen --
/// v1 used the shared [OnboardingScaffold] (flat paper background,
/// fixed padding); this design is different enough in kind (a full-
/// bleed gradient hero over a rounded white sheet, a pill button
/// instead of a button-plus-text-link pair) that it gets its own
/// `Scaffold` rather than forcing the new look through the old wrapper.
///
/// No back button -- removed per product decision; this screen sits at
/// the end of a required flow with nothing useful to go back to. No
/// "Not now" skip either -- location is "required to play" (the
/// screen's own chip copy), so `Enable Location` is the only action,
/// fixed at the bottom on its own.
///
/// Any permission error -- not just the permanently-denied case node
/// 235:6850 shows -- surfaces as the same floating `AppToast`, matching
/// that node's style rather than falling back to a plain inline red
/// line (what a bare `errorMessage` used to render as, before this
/// screen had a toast component to reuse for it).
///
/// Simplification: Figma fixes the header at a literal 313px and floats
/// the white sheet starting at 286px, so the sheet's rounded top corner
/// peeks out from under the header by 27px. This builds the header to
/// its natural content height instead of a hardcoded pixel figure (more
/// robust across device sizes) and gives the sheet its own rounded top
/// corners directly below it -- same visual read, without depending on
/// one fixed screen height to line the overlap up correctly.
class OnboardingPermissionPage extends StatelessWidget {
  const OnboardingPermissionPage({
    super.key,
    required this.isRequesting,
    this.isPermanentlyDenied = false,
    required this.errorMessage,
    required this.onEnableLocation,
  });

  final bool isRequesting;
  final bool isPermanentlyDenied;
  final String? errorMessage;
  final VoidCallback onEnableLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              const _PermissionHeader(),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x26000000),
                        offset: Offset(0, -8),
                        blurRadius: 18,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _PermissionFact(
                          icon: Icons.location_on_outlined,
                          title: 'Wakes only at boundaries.',
                          body:
                              "The phone's own geofencing nudges the app "
                              'when you cross into a new county no '
                              'constant GPS, almost no battery.',
                        ),
                        _PermissionFact(
                          icon: Icons.shield_outlined,
                          title: 'County entries, never traces.',
                          body:
                              'We store "entered Turkana on Saturday" not '
                              'where you went, stopped or slept.',
                        ),
                        _PermissionFact(
                          icon: Icons.cloud_outlined,
                          title: 'Works offline.',
                          body:
                              'Deep in Marsabit with no bars? The badge '
                              "lands on your phone and confirms when "
                              "you're back in coverage.",
                        ),
                        _PermissionFact(
                          icon: Icons.tune_outlined,
                          title: "You're in control.",
                          body:
                              'Switch to manual mode or delete your '
                              'location history anytime from Profile → '
                              'Location mode.',
                          isLast: true,
                        ),
                        SizedBox(height: 8),
                        _PermissionNote(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (errorMessage != null)
            Positioned(
              top: 58,
              left: 16,
              right: 16,
              child: AppToast(
                icon: Icons.gpp_bad_outlined,
                title: isPermanentlyDenied
                    ? 'Location permission is disabled.'
                    : 'Location permission needed.',
                message: errorMessage!,
                // "Open" (Settings) only makes sense once the OS has
                // permanently denied the prompt -- a plain first denial
                // can still be retried straight from Enable Location
                // below, so the toast there is informational only.
                actionLabel: isPermanentlyDenied ? 'Open' : null,
                onAction: isPermanentlyDenied ? onEnableLocation : null,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: _PermissionPillButton(
          label: isRequesting
              ? 'Requesting...'
              : (isPermanentlyDenied ? 'Open settings' : 'Enable Location'),
          onPressed: isRequesting ? null : onEnableLocation,
        ),
      ),
    );
  }
}

class _PermissionHeader extends StatelessWidget {
  const _PermissionHeader();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.permissionHeaderGradientEnd],
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            // Decorative soft glow (node 235:6796) -- a blurred
            // translucent-white circle bleeding off the header's
            // top-right corner.
            Positioned(
              top: -60,
              right: -60,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PermissionChip(),
                    const SizedBox(height: 10),
                    Text(
                      'We watch for county lines, not your route',
                      style: AppTextStyles.heroHeading,
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        // 14px/500/24px line height, slate-300 -- not
                        // toastMessage (same size but regular weight)
                        // or noteText (500 weight but 20px line
                        // height); this hero subheading is its own
                        // combination of the two.
                        style: AppTextStyles.noteText.copyWith(
                          color: AppColors.heroSubheadingText,
                          height: 24 / 14,
                        ),
                        children: const [
                          TextSpan(text: 'Without this, '),
                          TextSpan(
                            text: 'Kaunti47',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                " can't tell when you enter a new county "
                                "badges won't unlock on their own.",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle_outlined, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            'One permission . Required to Play',
            // This chip instance is set larger than the home-county
            // screen's identical "Chip" component (14px/24px line
            // height here vs. chipLabel's 12px/20px there) -- an
            // explicit per-instance override in the Figma file, not a
            // mistake to normalize away.
            style: AppTextStyles.chipLabel.copyWith(
              color: Colors.white,
              fontSize: 14,
              height: 24 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionFact extends StatelessWidget {
  const _PermissionFact({
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String body;

  /// The last row has no connecting divider line below it.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    // The 4th row ("You're in control.") was set at body-base (16px)
    // in the Figma file, one size up from the other three (14px) -- a
    // design mistake, not an intentional emphasis, per product
    // feedback. All four rows now share the same factBody style.
    final bodyStyle = AppTextStyles.factBody;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 21, color: AppColors.accent),
                ),
                if (!isLast) ...[
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(width: 1, color: AppColors.trackInactive),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Text.rich(
                  TextSpan(
                    // Figma sets both spans at the same weight (medium)
                    // -- only the color differentiates the bold-reading
                    // lead-in from its continuation.
                    text: title,
                    style: bodyStyle.copyWith(color: AppColors.factTitleText),
                    children: [TextSpan(text: ' $body', style: bodyStyle)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionNote extends StatelessWidget {
  const _PermissionNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.noteBackground,
        border: Border.all(color: AppColors.trackInactive),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline,
              size: 15,
              color: AppColors.noteMutedText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.noteText,
                children: const [
                  TextSpan(text: 'The system prompt comes next choose '),
                  TextSpan(
                    text: '"Allow all the time."',
                    style: TextStyle(color: AppColors.noteStrongText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Only ever the filled/accent variant now -- the unfilled "Not now"
/// skip button this was built to also support was removed (location is
/// "required to play", per the screen's own chip copy), so the
/// filled/unfilled switch that used to live here is gone too.
class _PermissionPillButton extends StatelessWidget {
  const _PermissionPillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.accent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(label, style: AppTextStyles.buttonLabel),
      ),
    );
  }
}
