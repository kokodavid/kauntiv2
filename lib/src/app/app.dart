import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_config.dart';
import '../counties/county_paths.dart';
import '../design/app_colors.dart';
import '../features/auth/application/sign_in_controller.dart';
import '../features/auth/data/app_auth_service.dart';
import '../features/map_home/application/map_home_board_loader.dart';
import '../features/map_home/data/supabase_map_home_repository.dart';
import '../features/map_home/presentation/map_home_screen.dart';
import '../features/profile/data/profile_setup_repository.dart';
import '../screens/onboarding/onboarding_auth_page.dart';
import '../screens/onboarding/onboarding_home_county_page.dart';
import '../screens/onboarding/onboarding_permission_page.dart';
import '../screens/splash_screen.dart';
import '../services/app_location_permission_service.dart';
import '../services/app_supabase.dart';

class App extends StatelessWidget {
  const App({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.appName,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.splashBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7A45)),
      ),
      home: _StartupGate(config: config),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.config});

  final AppConfig config;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate>
    with WidgetsBindingObserver {
  var _splashComplete = false;
  var _signedIn = false;
  var _needsHomeCounty = false;
  var _needsLocationPermission = false;
  var _isSavingCounty = false;
  var _isRequestingLocation = false;
  var _isLocationPermanentlyDenied = false;
  CountyPath? _selectedCounty;
  String? _homeCountyError;
  String? _permissionError;
  final _locationPermissionService = const AppLocationPermissionService();

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
    if (state == AppLifecycleState.resumed && _isLocationPermanentlyDenied) {
      unawaited(_recheckLocationPermission());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashComplete) {
      return SplashScreen(
        preload: _preloadSignInAssets,
        onComplete: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _splashComplete = true;
          });
        },
      );
    }

    if (_needsHomeCounty) {
      return OnboardingHomeCountyPage(
        selectedCounty: _selectedCounty,
        isSaving: _isSavingCounty,
        errorMessage: _homeCountyError,
        onSelected: (county) {
          setState(() {
            _selectedCounty = county;
            _homeCountyError = null;
          });
        },
        onContinue: _saveHomeCounty,
      );
    }

    if (_needsLocationPermission) {
      return OnboardingPermissionPage(
        isRequesting: _isRequestingLocation,
        isPermanentlyDenied: _isLocationPermanentlyDenied,
        errorMessage: _permissionError,
        onEnableLocation: _handleEnableLocationPressed,
      );
    }

    if (!_signedIn) {
      return _SignInHost(
        config: widget.config,
        onSignedIn: _handlePostSignInSetup,
      );
    }

    return MapHomeScreen(
      homeCounty: _selectedCounty,
      mapboxAccessToken: widget.config.mapboxAccessToken,
      loader: AppSupabase.isInitialized
          ? MapHomeBoardLoader(
              repository: SupabaseMapHomeRepository(AppSupabase.client),
            )
          : const MapHomeBoardLoader(),
    );
  }

  Future<void> _preloadSignInAssets(BuildContext context) async {
    await Future.wait([
      const SvgAssetLoader('assets/images/onboarding.svg').loadBytes(context),
      _restoreSessionState(),
    ]);
  }

  Future<void> _restoreSessionState() async {
    if (!AppSupabase.isInitialized ||
        AppSupabase.client.auth.currentUser == null) {
      return;
    }

    try {
      final homeCounty = await SupabaseProfileSetupRepository(
        AppSupabase.client,
      ).fetchHomeCounty();
      if (!mounted) {
        return;
      }

      await _handlePostSignInSetup(homeCounty, null);
    } catch (_) {
      if (!mounted) {
        return;
      }

      await _handlePostSignInSetup(
        null,
        'Could not check your saved home county. Pick it again to continue.',
      );
    }
  }

  Future<void> _saveHomeCounty() async {
    final county = _selectedCounty;
    if (county == null || _isSavingCounty) {
      return;
    }

    setState(() {
      _isSavingCounty = true;
      _homeCountyError = null;
    });

    try {
      await SupabaseProfileSetupRepository(AppSupabase.client).saveHomeCounty(
        county,
      );
      await _continueAfterHomeCounty();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _homeCountyError = 'Could not save your home county. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingCounty = false;
        });
      }
    }
  }

  Future<void> _handlePostSignInSetup(
    CountyPath? homeCounty,
    String? errorMessage,
  ) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedCounty = homeCounty;
      _homeCountyError = errorMessage;
      _permissionError = null;
      _needsHomeCounty = homeCounty == null;
      _needsLocationPermission = false;
      _signedIn = false;
    });

    if (homeCounty != null) {
      await _continueAfterHomeCounty();
    }
  }

  Future<void> _continueAfterHomeCounty() async {
    AppLocationPermissionResult result;
    try {
      result = await _locationPermissionService.checkStatus();
    } catch (_) {
      result = AppLocationPermissionResult.denied;
    }

    if (!mounted) {
      return;
    }

    if (result == AppLocationPermissionResult.granted) {
      setState(() {
        _needsHomeCounty = false;
        _needsLocationPermission = false;
        _isLocationPermanentlyDenied = false;
        _permissionError = null;
        _signedIn = true;
      });
      return;
    }

    setState(() {
      _needsHomeCounty = false;
      _needsLocationPermission = true;
      _isLocationPermanentlyDenied =
          result == AppLocationPermissionResult.permanentlyDenied;
      _permissionError = null;
      _signedIn = false;
    });
  }

  Future<void> _handleEnableLocationPressed() async {
    if (_isLocationPermanentlyDenied) {
      await _locationPermissionService.openSettings();
      return;
    }
    await _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isRequestingLocation = true;
      _permissionError = null;
    });

    try {
      final result = await _locationPermissionService.requestLocationAccess();
      if (!mounted) {
        return;
      }

      if (result == AppLocationPermissionResult.granted) {
        setState(() {
          _needsLocationPermission = false;
          _isLocationPermanentlyDenied = false;
          _permissionError = null;
          _signedIn = true;
        });
        return;
      }

      setState(() {
        _isLocationPermanentlyDenied =
            result == AppLocationPermissionResult.permanentlyDenied;
        _permissionError = switch (result) {
          AppLocationPermissionResult.permanentlyDenied =>
            'Location permission is disabled. Open settings and allow it to unlock badges automatically.',
          AppLocationPermissionResult.restricted =>
            'Location permission is restricted on this device.',
          AppLocationPermissionResult.denied =>
            'Location permission is needed to unlock county badges automatically.',
          AppLocationPermissionResult.granted => null,
        };
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _permissionError = 'Could not request location permission. Try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingLocation = false;
        });
      }
    }
  }

  Future<void> _recheckLocationPermission() async {
    final result = await _locationPermissionService.checkStatus();
    if (!mounted || result != AppLocationPermissionResult.granted) {
      return;
    }

    setState(() {
      _needsLocationPermission = false;
      _isLocationPermanentlyDenied = false;
      _permissionError = null;
      _signedIn = true;
    });
  }
}

class _SignInHost extends StatefulWidget {
  const _SignInHost({required this.config, required this.onSignedIn});

  final AppConfig config;
  final Future<void> Function(CountyPath? homeCounty, String? errorMessage)
  onSignedIn;

  @override
  State<_SignInHost> createState() => _SignInHostState();
}

class _SignInHostState extends State<_SignInHost> {
  final _authService = const AppAuthService();
  late final _signIn = SignInController(_authService, widget.config);
  AppAuthProvider? _checkingHomeCountyProvider;

  @override
  void dispose() {
    _signIn.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn(AppAuthProvider provider) async {
    await _signIn.signIn(provider);
    if (!mounted ||
        _signIn.failure != null ||
        _authService.currentUser == null) {
      return;
    }

    setState(() {
      _checkingHomeCountyProvider = provider;
    });

    try {
      final homeCounty = await SupabaseProfileSetupRepository(
        AppSupabase.client,
      ).fetchHomeCounty();
      if (!mounted) {
        return;
      }
      await widget.onSignedIn(homeCounty, null);
    } catch (_) {
      if (!mounted) {
        return;
      }
      await widget.onSignedIn(
        null,
        'Could not check your saved home county. Pick it again to continue.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingHomeCountyProvider = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _signIn,
      builder: (context, _) {
        return OnboardingAuthPage(
          onGoogle: () => _handleSignIn(AppAuthProvider.google),
          onApple: () => _handleSignIn(AppAuthProvider.apple),
          showApple: defaultTargetPlatform == TargetPlatform.iOS,
          isGoogleLoading:
              _signIn.providerInProgress == AppAuthProvider.google ||
              _checkingHomeCountyProvider == AppAuthProvider.google,
          isAppleLoading:
              _signIn.providerInProgress == AppAuthProvider.apple ||
              _checkingHomeCountyProvider == AppAuthProvider.apple,
          errorMessage: _signIn.errorMessage,
        );
      },
    );
  }
}
