import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/features/badges/domain/badge_collection.dart';
import 'package:kaunti47_v2/src/features/badges/domain/passport_book.dart';
import 'package:kaunti47_v2/src/features/badges/presentation/passport_share_card.dart';

void main() {
  // 22 Kiambu Bronze (latest), 47 Nairobi Explored, 30 Baringo passed through.
  final book = PassportBook.fromCollection(
    BadgeCollection.from(
      visitStates: {22: 'explored', 47: 'explored', 30: 'passed_through'},
      ranks: const {22: 'regular'},
      firstStampAt: DateTime.utc(2026, 9, 5, 9),
      exploredAt: {
        47: DateTime.utc(2026, 9, 5, 9),
        22: DateTime.utc(2026, 11, 2, 9),
      },
    ),
  );

  Future<void> pump(
    WidgetTester tester, {
    PassportShareStyle style = PassportShareStyle.passport,
    String? name = 'David Mochoge',
    bool showName = true,
    bool showUsername = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PassportShareCard(
            style: style,
            book: book,
            username: 'mochoge',
            holderName: name,
            showName: showName,
            showUsername: showUsername,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder text(String value) => find.textContaining(value, findRichText: true);

  testWidgets('passport style: name, username, count, legend, latest', (
    tester,
  ) async {
    await pump(tester);
    expect(text('David Mochoge'), findsOneWidget);
    expect(text('@mochoge'), findsOneWidget);
    expect(text('First stamp 5 Sep 2026'), findsOneWidget);
    expect(text('2'), findsWidgets);
    expect(text('/ 47'), findsOneWidget);
    expect(text('Explored'), findsWidgets);
    expect(text('Passed through'), findsOneWidget);
    expect(text('Silver'), findsNothing); // a level nobody has stays out
    expect(text('LATEST STAMP'), findsOneWidget);
    expect(text('Kiambu'), findsOneWidget);
    expect(tester.takeException(), isNull); // nothing overflows
  });

  testWidgets('the @username can be turned off, kaunti47.com stays', (
    tester,
  ) async {
    await pump(tester, showUsername: false);
    expect(text('@mochoge'), findsNothing);
    expect(text('kaunti47.com'), findsOneWidget);
    await pump(tester, style: PassportShareStyle.photo, showUsername: false);
    expect(text('@mochoge'), findsNothing);
    expect(text('kaunti47.com'), findsOneWidget);
  });

  testWidgets('with the name off the @username still shows', (tester) async {
    await pump(tester, showName: false);
    expect(text('David Mochoge'), findsNothing);
    expect(text('@mochoge'), findsOneWidget);
  });

  testWidgets('no name at all still shows the @username', (tester) async {
    await pump(tester, name: '  ');
    expect(text('@mochoge'), findsOneWidget);
  });

  testWidgets('photo style keeps the @username with the name off', (
    tester,
  ) async {
    await pump(tester, style: PassportShareStyle.photo, showName: false);
    expect(text('David Mochoge'), findsNothing);
    expect(text('@mochoge'), findsOneWidget);
    expect(text('of 47 counties explored'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a very long name stays on one line', (tester) async {
    await pump(tester, name: 'Wanjiru Njeri Wambui Kamau Otieno Achieng');
    expect(tester.takeException(), isNull);
  });
}
