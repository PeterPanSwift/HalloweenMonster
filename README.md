# 萬聖節妖怪圖鑑 Halloween Monsters

用 Flutter 製作的萬聖節妖怪介紹 App，收錄 10 隻經典傳說生物：南瓜燈傑克、吸血鬼、狼人、科學怪人、木乃伊、女巫、幽靈、骷髏、無頭騎士、報喪女妖。

- 首頁：星空與飛行蝙蝠動畫、今夜最恐怖、妖怪卡片圖鑑、隨機召喚
- 詳細頁：起源、恐怖指數、傳說故事、特殊能力、弱點、冷知識
- 圖片來源頁：每張圖片的作者與授權

## 圖片

圖片全部來自 [Wikimedia Commons](https://commons.wikimedia.org/) 的公有領域或創用 CC 授權作品，由 `tool/fetch_images.py`（GitHub Actions：*Fetch monster images*）搜尋並下載候選圖，再挑選放進 `assets/monsters/`。作者與授權資訊在 `lib/data/monsters.dart`，App 內的「圖片與字型來源」頁也會列出。

## App Icon

`tool/make_icon.py` 繪製 `assets/icon/app_icon.png`，再用 `flutter_launcher_icons` 產生 iOS / Android 各尺寸：

```sh
python3 tool/make_icon.py
dart run flutter_launcher_icons
```

## 錄影與上架截圖（GitHub Actions）

`.github/workflows/record.yml`：

1. **iPhone 18 Pro Max**（macOS runner）與 **Pixel 10**（Ubuntu runner + Android 16 模擬器）上執行 `integration_test/demo_test.dart`
2. `MODE=shots`：停在各畫面時由 `simctl` / `adb` 截圖（狀態列固定為 9:41、滿電）
3. `MODE=video`：錄下整段操作，測試輸出的 `@@MARK START/END` 時間戳用來裁掉 App 啟動前後的多餘片段
4. `tool/ci/process_media.py` 用 ffmpeg 裁剪並壓縮影片（H.264、1280p、30fps），`tool/store_shots.py` 產生 App Store（1320×2868）與 Google Play（1080×1920）宣傳截圖
5. 結果推到 `media` 分支

## 開發

```sh
flutter pub get
flutter test
flutter run
```
