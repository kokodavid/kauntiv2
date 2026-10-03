import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/app_config_provider.dart';
import '../design/app_colors.dart';
import 'router.dart';

/// The app: [MaterialApp.router] on [appRouterProvider]. Start-up and
/// onboarding live in `StartupFlow`; the router redirects on it.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: ref.watch(appConfigProvider).appName,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.splashBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7A45)),
        // Material 3 derives a bottom sheet's surface tint and a focused
        // input's border from the color scheme's seed by default, which is
        // the old brand green above -- explicit here so every sheet and
        // text field reads as the app's actual (blue) accent instead.
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.sheetBackground,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(
              color: AppColors.inputFocusedBorder,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.danger, width: 1.5),
          ),
        ),
      ),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
