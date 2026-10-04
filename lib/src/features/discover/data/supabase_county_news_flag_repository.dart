import 'package:supabase_flutter/supabase_flutter.dart';

import 'county_news_flag_repository.dart';

class SupabaseCountyNewsFlagRepository implements CountyNewsFlagRepository {
  const SupabaseCountyNewsFlagRepository(this.client);

  final SupabaseClient client;

  @override
  Future<bool> isEnabled() async {
    final row = await client
        .from('app_feature_flags')
        .select('enabled')
        .eq('feature_key', 'county_news')
        .maybeSingle();
    return row?['enabled'] == true;
  }
}
