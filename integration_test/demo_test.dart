// CI 錄影與截圖的操作腳本（tool/ci/record.sh 會用 -t 把這個檔案編成 App）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halloween_monster/main.dart' as app;

import 'demo_helpers.dart';

Finder byKey(String key) => find.byKey(Key(key));

void main() {
  setUpDemoBinding();

  testWidgets('demo ($demoMode)', (tester) async {
    await startDemo(tester, app.main);
    if (demoMode == 'shots') {
      await _shots(tester);
      mark('DONE');
    } else {
      mark('START');
      await _video(tester);
      mark('END');
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}

Future<void> _back(WidgetTester tester) =>
    tap(tester, byKey('backButton'), after: 1300);

Future<void> _video(WidgetTester tester) async {
  await pause(tester, 2200);

  // 今夜最恐怖：無頭騎士
  await tap(tester, byKey('featuredCard'));
  await drag(tester, byKey('detailScroll'), -420);
  await drag(tester, byKey('detailScroll'), -420);
  await _back(tester);

  // 瀏覽圖鑑並打開吸血鬼，再看下一隻
  await drag(tester, byKey('monsterList'), -380);
  await tap(tester, byKey('card-vampire'));
  await drag(tester, byKey('detailScroll'), -450);
  await drag(tester, byKey('detailScroll'), -600, ms: 700);
  await drag(tester, byKey('detailScroll'), -600, ms: 700);
  await tap(tester, byKey('nextButton'));
  await drag(tester, byKey('detailScroll'), -400);
  await _back(tester);

  // 繼續往下看
  await drag(tester, byKey('monsterList'), -520);
  await tap(tester, byKey('card-witch'));
  await drag(tester, byKey('detailScroll'), -420);
  await _back(tester);

  // 隨機召喚
  await tap(tester, byKey('randomButton'), after: 2000);
  await _back(tester);

  // 回到頂端看圖片來源
  await drag(tester, byKey('monsterList'), 1400);
  await tap(tester, byKey('creditsButton'), after: 1500);
  await tester.pageBack();
  await pause(tester, 1500);
}

Future<void> _shots(WidgetTester tester) async {
  await shot(tester, '01_home');

  await drag(tester, byKey('monsterList'), -430);
  await shot(tester, '02_collection');

  await tap(tester, byKey('card-vampire'));
  await shot(tester, '03_detail');

  await drag(tester, byKey('detailScroll'), -470);
  await shot(tester, '04_story');
  await _back(tester);

  await drag(tester, byKey('monsterList'), -520);
  await tap(tester, byKey('card-witch'));
  await shot(tester, '05_witch');
}
