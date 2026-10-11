import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaunti47_v2/src/counties/county_paths.dart';
import 'package:kaunti47_v2/src/features/map_home/domain/map_home_models.dart';
import 'package:kaunti47_v2/src/features/map_home/presentation/county_peek_sheet.dart';
import 'package:kaunti47_v2/src/features/map_home/presentation/real_map_sheets.dart';

MapHomeCountyBadge _badge(int code) => MapHomeCountyBadge(
  county: CountyPaths.byCode[code]!,
  state: MapHomeCountyBadgeState.locked,
);

void main() {
  testWidgets('tapping another county swaps the open peek, never stacks', (
    tester,
  ) async {
    var closed = 0;
    final sheets = RealMapSheets(onPeekClosed: () => closed++);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    );

    sheets.showCounty(context, _badge(47), isHome: false);
    await tester.pumpAndSettle();
    expect(find.byType(CountyPeekSheet), findsOneWidget);

    sheets.showCounty(context, _badge(1), isHome: false);
    await tester.pumpAndSettle();
    expect(find.byType(CountyPeekSheet), findsOneWidget);
    expect(find.text(CountyPaths.byCode[1]!.name), findsWidgets);
    expect(closed, 0);

    sheets.closePeek();
    await tester.pumpAndSettle();
    expect(find.byType(CountyPeekSheet), findsNothing);
    expect(closed, 1);
    sheets.dispose();
  });
}
