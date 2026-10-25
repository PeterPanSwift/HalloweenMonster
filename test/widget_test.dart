import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halloween_monster/data/monsters.dart';
import 'package:halloween_monster/main.dart';

void main() {
  testWidgets('home shows the monster guide and opens a detail page', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const HalloweenMonsterApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('萬聖節妖怪圖鑑'), findsOneWidget);
    expect(find.byKey(const Key('featuredCard')), findsOneWidget);

    await tester.tap(find.byKey(const Key('featuredCard')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('無頭騎士'), findsWidgets);
    expect(find.text('傳說故事'), findsOneWidget);
  });

  test('every monster has complete data and a credited image', () {
    expect(monsters, hasLength(10));
    for (final m in monsters) {
      expect(m.scareLevel, inInclusiveRange(1, 5));
      expect(m.powers, isNotEmpty);
      expect(m.credit.url, startsWith('https://commons.wikimedia.org/wiki/File:'));
    }
  });
}
