import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/core/domain/place_type.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_board.dart';
import 'package:kaunti47_v2/src/features/discover/domain/explore_entries.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_board_memo.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_chapter.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_dock_collapse.dart';
import 'package:kaunti47_v2/src/features/discover/presentation/explore_field_place_card.dart';

ExplorePlace _place(int i) => ExplorePlace(
  id: 'p$i',
  title: 'Place $i',
  description: '',
  category: PlaceType.park,
  saved: false,
);

ExploreEntry _entry(int i) => ExploreEntry(
  place: _place(i),
  countyCode: 1,
  countyName: CountyPaths.byCode[1]!.name,
  claimed: false,
);

/// Counts its own builds, so a test can tell a rebuild from a notifier tick.
class _Harness extends ConsumerStatefulWidget {
  const _Harness({super.key, required this.onBuild});

  final VoidCallback onBuild;

  @override
  ConsumerState<_Harness> createState() => _HarnessState();
}

class _HarnessState extends ConsumerState<_Harness>
    with ExploreDockCollapse<_Harness> {
  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              handleScroll(notification);
              return false;
            },
            child: ListView(
              children: [
                for (var i = 0; i < 60; i++)
                  SizedBox(height: 80, child: Text('row $i')),
              ],
            ),
          ),
        ),
        const ExploreDockSlot(searching: false, child: SizedBox(height: 40)),
      ],
    );
  }

  bool get collapsed => dockCollapsed;
}

void main() {
  testWidgets('a chapter builds only the cards near the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ExploreChapter(
              kicker: '',
              title: 'Parks',
              places: [for (var i = 0; i < 30; i++) _entry(i)],
              showHeader: false,
            ),
          ),
        ),
      ),
    );
    final built = tester.widgetList(find.byType(ExploreFieldPlaceCard)).length;
    expect(built, greaterThan(0));
    expect(built, lessThan(6));
    expect(find.text('Place 25'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(-5000, 0));
    await tester.pumpAndSettle();
    expect(find.text('Place 0'), findsNothing);
  });

  testWidgets('folding the dock does not rebuild the screen', (tester) async {
    var builds = 0;
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: _Harness(key: key, onBuild: () => builds++),
          ),
        ),
      ),
    );
    expect(builds, 1);
    expect(key.currentState!.collapsed, isFalse);

    // Scrolling down folds the dock; scrolling back up brings it back.
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(key.currentState!.collapsed, isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(key.currentState!.collapsed, isFalse);

    expect(builds, 1);
  });

  test('the board memo reuses results for the same board and query', () {
    // ignore: prefer_const_constructors
    final board = ExploreBoard(featuredUnlock: null, mine: []);
    final memo = ExploreBoardMemo();
    expect(identical(memo.entries(board), memo.entries(board)), isTrue);
    expect(
      identical(memo.filtered(board, 'a'), memo.filtered(board, 'a')),
      isTrue,
    );
    expect(identical(memo.filtered(board, ''), board), isTrue);

    // ignore: prefer_const_constructors
    final other = ExploreBoard(featuredUnlock: null, mine: []);
    final first = memo.entries(board);
    expect(identical(memo.entries(other), first), isFalse);
  });
}
