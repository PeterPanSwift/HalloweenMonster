// 在模擬器上自動操作 App，供 CI 錄影與截圖使用。
//
// MODE=video：完整操作流程，前後輸出 @@MARK 時間戳，CI 依此裁掉多餘片段。
// MODE=shots：停在各個畫面並輸出 @@SHOT，CI 收到後用 simctl / adb 截圖。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halloween_monster/main.dart' as app;
import 'package:integration_test/integration_test.dart';

const mode = String.fromEnvironment('MODE', defaultValue: 'video');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('demo ($mode)', (tester) async {
    debugPrint('@@READY');
    app.main();
    // iOS 模擬器上的 debug 版第一個畫面要好幾秒才出來
    await wait(tester, 8000);
    if (mode == 'shots') {
      await shots(tester);
    } else {
      await video(tester);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

void mark(String name) =>
    debugPrint('@@MARK $name ${DateTime.now().millisecondsSinceEpoch}');

Future<void> wait(WidgetTester tester, int ms) =>
    tester.pump(Duration(milliseconds: ms));

Future<void> scroll(
  WidgetTester tester,
  String key,
  double dy, {
  int ms = 900,
}) async {
  await tester.timedDrag(
    find.byKey(Key(key)).first,
    Offset(0, dy),
    Duration(milliseconds: ms),
  );
  await wait(tester, 900);
}

Future<void> tap(WidgetTester tester, String key, {int after = 1600}) async {
  final target = find.byKey(Key(key)).first;
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await wait(tester, 600);
  }
  await tester.tap(target);
  await wait(tester, after);
}

Future<void> back(WidgetTester tester) =>
    tap(tester, 'backButton', after: 1300);

Future<void> video(WidgetTester tester) async {
  mark('START');
  await wait(tester, 2200);

  // 今夜最恐怖：無頭騎士
  await tap(tester, 'featuredCard');
  await scroll(tester, 'detailScroll', -420);
  await scroll(tester, 'detailScroll', -420);
  await back(tester);

  // 瀏覽圖鑑並打開吸血鬼
  await scroll(tester, 'monsterList', -380);
  await tap(tester, 'card-vampire');
  await scroll(tester, 'detailScroll', -450);
  await scroll(tester, 'detailScroll', -600, ms: 700);
  await scroll(tester, 'detailScroll', -600, ms: 700);
  await tap(tester, 'nextButton'); // 下一隻：狼人
  await scroll(tester, 'detailScroll', -400);
  await back(tester);

  // 繼續往下看
  await scroll(tester, 'monsterList', -520);
  await wait(tester, 500);
  await tap(tester, 'card-witch');
  await scroll(tester, 'detailScroll', -420);
  await back(tester);

  // 隨機召喚
  await tap(tester, 'randomButton', after: 2000);
  await back(tester);

  // 回到頂端看圖片來源
  await scroll(tester, 'monsterList', 1400, ms: 900);
  await tap(tester, 'creditsButton', after: 1500);
  await tester.pageBack();
  await wait(tester, 1500);
  mark('END');
}

// iOS 的 log stream 可能延遲好幾秒，所以也把畫面名稱寫進 App 的 tmp 資料夾，
// CI 直接從模擬器的 App container 輪詢這個檔案。
Future<void> shot(WidgetTester tester, String name) async {
  await wait(tester, 1500);
  debugPrint('@@SHOT $name');
  File('${Directory.systemTemp.path}/hm_shot.txt').writeAsStringSync(name);
  await wait(tester, 6000);
}

Future<void> shots(WidgetTester tester) async {
  await shot(tester, '01_home');

  await scroll(tester, 'monsterList', -430);
  await shot(tester, '02_collection');

  await tap(tester, 'card-vampire');
  await shot(tester, '03_detail');

  await scroll(tester, 'detailScroll', -470);
  await shot(tester, '04_story');
  await back(tester);

  await scroll(tester, 'monsterList', -520);
  await tap(tester, 'card-witch');
  await shot(tester, '05_witch');
  mark('DONE');
}
