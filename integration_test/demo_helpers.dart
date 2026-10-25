// 給 CI 錄影與截圖用的 integration_test 小工具，搭配 tool/ci/record.sh。
//
// 測試會被編成 App 直接啟動（不經過 flutter test），透過兩個管道與 CI 溝通：
// - 裝置 log：@@READY、@@SHOT <名稱> <tmp 路徑>、@@MARK <START|END|DONE> <毫秒時間戳>
// - App tmp 資料夾：demo_shot.txt（iOS 的 log 會延遲，CI 輪詢這個檔案）與
//   demo_shot_ack.txt（CI 截完圖後寫入，測試收到才繼續）
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// `--dart-define=MODE=shots|video`
const demoMode = String.fromEnvironment('MODE', defaultValue: 'video');

/// 本機乾跑（scripts/dry_run.sh）時設定手機尺寸，讓版面與實機相同。
const _dryRun = bool.fromEnvironment('DEMO_DRY_RUN');

/// 在 main() 一開始呼叫。fullyLive 讓動畫照真實時間播放，錄起來才自然。
void setUpDemoBinding() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
}

/// 啟動 App 並等第一個畫面穩定。iOS 模擬器上的 debug 版第一個畫面要 4 秒左右才出來，
/// 所以預設等 8 秒；CI 會從 START 開始裁剪，等待的時間不會出現在影片裡。
Future<void> startDemo(
  WidgetTester tester,
  void Function() runApp, {
  int settleMs = 8000,
}) async {
  if (_dryRun) {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
  }
  debugPrint('@@READY');
  runApp();
  await pause(tester, settleMs);
}

/// 影片的起訖點（START / END）或截圖流程結束（DONE）。
void mark(String name) =>
    debugPrint('@@MARK $name ${DateTime.now().millisecondsSinceEpoch}');

/// 等待真實時間並持續繪製畫面。App 有無限循環的動畫時不能用 pumpAndSettle（會等到逾時）。
Future<void> pause(WidgetTester tester, int ms) =>
    tester.pump(Duration(milliseconds: ms));

/// 像真人一樣慢慢拖動（timedDrag 會照時間送出觸控事件，影片看得到捲動過程）。
Future<void> drag(
  WidgetTester tester,
  Finder target,
  double dy, {
  int ms = 900,
  int after = 900,
}) async {
  await tester.timedDrag(
    target.first,
    Offset(0, dy),
    Duration(milliseconds: ms),
  );
  await pause(tester, after);
}

/// 點擊；目標不在畫面上時先捲到看得見的位置，避免點到空白處。
Future<void> tap(WidgetTester tester, Finder target, {int after = 1600}) async {
  final f = target.first;
  if (f.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      f,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await pause(tester, 600);
  }
  await tester.tap(f);
  await pause(tester, after);
}

/// 停在目前畫面讓 CI 截圖，並等 CI 回報「截好了」才繼續（握手）。
///
/// 模擬器上第一次截圖可能要 6～11 秒、iOS 的 log 也會延遲，固定等待時間一定會遇到截到下一個畫面的情況，
/// 所以 CI 截完圖後會把名稱寫進 App tmp 資料夾的 demo_shot_ack.txt，這裡輪詢到才往下走。
/// 名稱就是截圖檔名（只用英數字與底線），也是 tool/ci/store.json 裡 captions 的 key。
Future<void> shot(
  WidgetTester tester,
  String name, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  await pause(tester, 1500);
  final dir = Directory.systemTemp.path;
  final ack = File('$dir/demo_shot_ack.txt');
  if (ack.existsSync()) ack.deleteSync();
  debugPrint('@@SHOT $name $dir');
  File('$dir/demo_shot.txt').writeAsStringSync(name);
  if (_dryRun) {
    await pause(tester, 500);
    return;
  }
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await pause(tester, 250);
    if (ack.existsSync() && ack.readAsStringSync().trim() == name) {
      await pause(tester, 300);
      return;
    }
  }
  debugPrint('@@WARN no screenshot ack for $name');
}
