import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/arrival_notifier.dart';

part 'arrival_notifier_provider.g.dart';

/// The arrival notification's OS permission and tap plumbing. Onboarding
/// asks through it; tests override it.
@Riverpod(keepAlive: true)
ArrivalNotifier arrivalNotifier(Ref ref) => ArrivalNotifier();
