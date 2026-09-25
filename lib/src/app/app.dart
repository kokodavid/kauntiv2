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
      title: ref.watch(appConfigProvider).appName,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.splashBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7A45)),
      ),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
