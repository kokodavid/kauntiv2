import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../counties/county_paths.dart';

abstract interface class ProfileSetupRepository {
  /// The home county remembered on this phone for the signed-in account,
  /// or null when none has been stored yet. Never touches the network, so
  /// start-up can use it offline.
  Future<CountyPath?> cachedHomeCounty();

  Future<CountyPath?> fetchHomeCounty();
  Future<void> saveHomeCounty(CountyPath? county);
}

class SupabaseProfileSetupRepository implements ProfileSetupRepository {
  const SupabaseProfileSetupRepository(this.client);

  final SupabaseClient client;

  String _owner() {
    final owner = client.auth.currentUser?.id;
    if (owner == null) {
      throw StateError('Profile setup requires a session');
    }
    return owner;
  }

  static String _cacheKey(String owner) => 'profile.home_county_slug.$owner';

  Future<void> _remember(String owner, CountyPath? county) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (county == null) {
        await prefs.remove(_cacheKey(owner));
      } else {
        await prefs.setString(_cacheKey(owner), county.slug);
      }
    } on Object {
      // The copy on this phone is only a speed-up; losing it is harmless.
    }
  }

  @override
  Future<CountyPath?> cachedHomeCounty() async {
    final owner = client.auth.currentUser?.id;
    if (owner == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final slug = prefs.getString(_cacheKey(owner));
      return slug == null ? null : CountyPaths.bySlug[slug];
    } on Object {
      return null;
    }
  }

  @override
  Future<CountyPath?> fetchHomeCounty() async {
    final owner = _owner();
    final county = await _fetchFromServer(owner);
    await _remember(owner, county);
    return county;
  }

  Future<CountyPath?> _fetchFromServer(String owner) async {
    final row = await client
        .from('profiles')
        .select('home_county_id, home_county_slug')
        .eq('id', owner)
        .maybeSingle()
        .timeout(const Duration(seconds: 8));

    final slug = row?['home_county_slug'] as String?;
    if (slug != null && CountyPaths.bySlug.containsKey(slug)) {
      return CountyPaths.bySlug[slug];
    }

    final code = row?['home_county_id'] as int?;
    if (code == null) {
      return null;
    }

    for (final county in CountyPaths.all) {
      if (county.code == code) {
        return county;
      }
    }
    return null;
  }

  @override
  Future<void> saveHomeCounty(CountyPath? county) async {
    final owner = _owner();
    await client
        .from('profiles')
        .upsert({
          'id': owner,
          'home_county_id': county?.code,
          'home_county_slug': county?.slug,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .timeout(const Duration(seconds: 8));
    await _remember(owner, county);
  }
}
