import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';

void main() {
  test('place types resolve keys and old spellings to the list', () {
    expect(PlaceType.of('park'), PlaceType.park);
    expect(PlaceType.of('museum'), PlaceType.museum);
    expect(PlaceType.of('Hot Spring'), PlaceType.hotSpring);
    expect(PlaceType.of('hot_spring'), PlaceType.hotSpring);
    expect(PlaceType.of('shore'), PlaceType.beach);
    expect(PlaceType.of('heritage'), PlaceType.historicSite);
    expect(PlaceType.of(' Hiking '), PlaceType.hike);
    expect(PlaceType.of('country_club'), PlaceType.countryClub);
    expect(PlaceType.of('Country clubs'), PlaceType.countryClub);
    expect(PlaceType.countryClub.family, PlaceTypeFamily.other);
    expect(PlaceType.countryClub.pluralLabel, 'Country clubs');
  });

  test('an unlisted type keeps its own name instead of a wrong category', () {
    final type = PlaceType.of('something-new');
    expect(type.isListed, isFalse);
    expect(type.key, 'something_new');
    expect(type.label, 'Something new');
    expect(PlaceType.of(''), PlaceType.unknown);
    expect(PlaceType.unknown.label, 'Place');
  });

  test('the app list matches the place_types migration', () {
    final migrations = [
      'supabase/migrations/20261018100000_place_types.sql',
      'supabase/migrations/20261109130000_country_club_place_type.sql',
    ];
    final keys = <String?>[];
    for (final migration in migrations) {
      final sql = File(migration).readAsStringSync();

      final typesBlock = sql.substring(
        sql.indexOf('insert into public.place_types'),
        sql.indexOf('on conflict (key)'),
      );
      keys.addAll(
        RegExp(
          r"\('([a-z_]+)', '",
        ).allMatches(typesBlock).map((match) => match.group(1)),
      );

      final aliasBlock = sql.substring(
        sql.indexOf('insert into public.place_type_aliases'),
        sql.indexOf('on conflict (alias)'),
      );
      final aliases = RegExp(
        r"\('([a-z ]+)', '([a-z_]+)'\)",
      ).allMatches(aliasBlock);
      expect(aliases, isNotEmpty);
      for (final alias in aliases) {
        expect(
          PlaceType.of(alias.group(1)!).key,
          alias.group(2),
          reason: 'alias "${alias.group(1)}"',
        );
      }
    }
    expect(keys, [for (final type in PlaceType.all) type.key]);
  });
}
