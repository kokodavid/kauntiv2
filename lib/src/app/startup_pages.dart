import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../features/auth/application/sign_in_controller.dart';
import '../features/auth/domain/auth_failure.dart';
import '../features/onboarding/application/startup_flow.dart';
import '../screens/onboarding/onboarding_auth_page.dart';
import '../screens/onboarding/onboarding_home_county_page.dart';
import '../screens/onboarding/onboarding_permission_page.dart';
import '../screens/splash_screen.dart';

/// The start-up pages, each bound to [StartupFlow] (or sign-in). Which
/// one shows is the router's call (`AppRoutes.redirect`).

/// Splash: decodes the sign-in artwork and restores a saved session
/// before it hands over, so the next page is the right one first time.
class StartupSplashPage extends ConsumerWidget {
  const StartupSplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.read(startupFlowProvider.notifier);
    return SplashScreen(
      preload: (context) => Future.wait([
        const SvgAssetLoader('assets/images/onboarding.svg').loadBytes(context),
        flow.restoreSession(),
      ]),
      onComplete: flow.completeSplash,
    );
  }
}

class StartupSignInPage extends ConsumerWidget {
  const StartupSignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signInControllerProvider);
    final signIn = ref.read(signInControllerProvider.notifier);
    return OnboardingAuthPage(
      onGoogle: () => unawaited(signIn.signIn(AppAuthProvider.google)),
      onApple: () => unawaited(signIn.signIn(AppAuthProvider.apple)),
      showApple: defaultTargetPlatform == TargetPlatform.iOS,
      isGoogleLoading: state.providerInProgress == AppAuthProvider.google,
      isAppleLoading: state.providerInProgress == AppAuthProvider.apple,
      errorMessage: state.errorMessage,
    );
  }
}

class StartupHomeCountyPage extends ConsumerWidget {
  const StartupHomeCountyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(startupFlowProvider);
    final flow = ref.read(startupFlowProvider.notifier);
    return OnboardingHomeCountyPage(
      selectedCounty: state.homeCounty,
      isSaving: state.isSavingCounty,
      errorMessage: state.homeCountyError,
      onSelected: flow.selectCounty,
      onContinue: flow.saveHomeCounty,
    );
  }
}

/// Location permission. Coming back from the OS settings re-checks it.
class StartupPermissionPage extends ConsumerStatefulWidget {
  const StartupPermissionPage({super.key});

  @override
  ConsumerState<StartupPermissionPage> createState() =>
      _StartupPermissionPageState();
}

class _StartupPermissionPageState extends ConsumerState<StartupPermissionPage>
    with WidgetsBindingObserver {
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
      unawaited(ref.read(startupFlowProvider.notifier).recheckPermission());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(startupFlowProvider);
    return OnboardingPermissionPage(
      isRequesting: state.isRequestingLocation,
      isPermanentlyDenied: state.isLocationPermanentlyDenied,
      errorMessage: state.permissionError,
      onEnableLocation: ref.read(startupFlowProvider.notifier).enableLocation,
    );
  }
}
