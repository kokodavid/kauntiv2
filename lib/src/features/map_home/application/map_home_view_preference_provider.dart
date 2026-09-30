import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/map_home_view_preference.dart';

part 'map_home_view_preference_provider.g.dart';

@riverpod
MapHomeViewPreference mapHomeViewPreference(Ref ref) =>
    const MapHomeViewPreference();
