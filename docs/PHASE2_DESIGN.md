# Phase 2 設計書 — カスタマイズと設定機能

## 1. 目的

Phase 2では、現在コードに固定されているフォント、配色、しきい値、表示内容、更新間隔などを、macOSの設定画面から変更できるようにする。

併せてCodex版とClaude版で重複しているUI・設定処理を共通化し、将来のサービス追加や履歴表示に耐えられる構造へ整理する。

## 2. 基本方針

- 設定値は `NSUserDefaults` に保存する
- 設定変更はアプリ再起動なしで即座に反映する
- CodexとClaude Codeは個別設定と共通設定の両方を持てるようにする
- ライト／ダークモード、アクセシビリティ、複数ディスプレイを維持する
- 会話本文を読み取らず、追加のAPI通信も発生させない
- 既存のClaude Code `statusLine` を失わず復元できるようにする

## 3. 設定画面

メニューバーの詳細画面に「設定…」ボタンを追加し、通常のmacOS設定ウインドウを開く。

設定画面は以下のタブで構成する。

1. 一般
2. 外観
3. 表示項目
4. 通知
5. データ
6. 詳細

## 4. 外観設定

### 4.1 フォント

- システム標準
- SF Pro
- SF Pro Rounded
- システム等幅フォント
- Avenir Next
- Macへインストール済みのフォント
- メニューバーと詳細画面の個別指定
- 文字サイズ
- 太さ
- 数字の等幅表示
- ライブプレビュー
- デフォルトへ戻す

メニューバーの推奨サイズは11〜15ptとする。幅が大きくなりすぎる組み合わせには注意を表示する。

### 4.2 カラー

プリセット：

- System
- Codex Blue
- Claude Purple
- Monochrome
- High Contrast
- Pastel
- Custom

カスタマイズ対象：

- Codexアクセント
- Claudeアクセント
- 通常時
- 注意時
- 警告時
- プログレスバー背景
- メインテキスト
- サブテキスト

色選択にはmacOS標準のカラーピッカーを使用する。

### 4.3 使用率しきい値

デフォルト値：

| 使用率 | 色 |
|---:|---|
| 0〜59% | 緑 |
| 60〜84% | オレンジ |
| 85〜100% | 赤 |

変更可能な項目：

- 注意色へ切り替える使用率
- 警告色へ切り替える使用率
- 色分けの有効／無効
- 使用量基準／残量基準

### 4.4 テーマ

- システム設定に従う
- ライト
- ダーク
- 高コントラスト
- `Reduce Transparency` への追従

## 5. メニューバー表示設定

### 5.1 表示テンプレート

プリセット例：

- `Codex 61%`
- `Codex使用率 61%`
- `Codex 残り39%`
- `61%`
- アイコン＋使用率
- アイコンのみ

設定項目：

- サービス名
- 「使用率」ラベル
- `%`記号
- 使用量／残量
- 小数点以下
- アイコン
- モノクロ／カラー
- CodexとClaudeを別項目または1項目に統合
- 表示順序
- メニューバー幅の上限

統合表示例：

- `AI 61% / 32%`
- `Cdx 61% · Cld 32%`
- 上限に近いサービスだけ表示

### 5.2 詳細画面

以下を個別に表示／非表示、並べ替え可能にする。

- 利用枠使用率
- 残り使用率
- リセット日時
- リセットまでの残り時間
- セッション累計トークン
- 入力／出力／キャッシュ済みトークン
- コンテキスト使用率
- モデル名
- プラン
- データ最終更新日時

## 6. 一般設定

- Macログイン時に自動起動
- 自動更新の有効／無効
- 更新間隔：1秒、5秒、15秒、30秒、1分
- ポップオーバーを開いたときに即時更新
- データが古い場合の警告
- 手動更新
- 更新失敗時の再試行
- Dockアイコンの表示／非表示
- 日本語／英語
- 12時間／24時間表記
- 数値の桁区切り
- 設定の初期化
- 設定のエクスポート／インポート

可能であれば定期的な全ファイル走査をファイル更新監視へ置き換え、CPU・消費電力を抑える。

## 7. 通知設定

通知条件：

- 注意しきい値へ到達
- 警告しきい値へ到達
- 90%、95%、100%到達
- 利用枠のリセット
- リセットまでの残り時間が指定値以下
- データ取得が一定時間停止

通知オプション：

- Codex／Claudeごとの有効化
- サウンド
- 同一利用枠では一度だけ通知
- 再通知間隔
- 集中モードへの配慮
- 通知から詳細画面を開く

通知済み状態は利用枠の識別子またはリセット時刻と併せて保存し、重複通知を防止する。

## 8. データ設定

### 8.1 Codex

- `~/.codex/sessions` の自動検出
- 保存先の手動指定
- 最新セッション／全セッションの選択
- アーカイブ済みセッションを含めるか
- データが見つからない場合の診断

### 8.2 Claude Code

- `statusLine` 設定状況の確認
- 中継スクリプトのインストール／再インストール
- 既存 `statusLine` との競合検出
- 元の設定への復元
- キャッシュ場所の表示
- キャッシュのクリア

### 8.3 プライバシーと診断

- 読み取るファイルの一覧
- 最後に読み取ったファイルと時刻
- 外部通信がないことの表示
- 会話本文を処理しないことの明示
- 機密情報を除外した診断情報のコピー

## 9. 複数ディスプレイ

- すべてのメニューバーへ表示
- メインディスプレイだけ表示
- ディスプレイ接続・取り外し時の再配置
- macOSの「ディスプレイごとに個別の操作スペース」が無効な場合の案内

macOSの制約で完全に制御できない項目は、設定画面で理由と必要なシステム設定を案内する。

## 10. 詳細設定

- デバッグログとログレベル
- 最後に解析した利用量イベント
- データ取得テスト
- 通知テスト
- 疑似使用率による表示プレビュー
- データフォルダをFinderで開く
- アプリ／Codex／Claude Codeのバージョン
- GitHubリポジトリを開く
- Issue報告

## 11. 内部設計

設定をUIコードへ直接埋め込まず、以下の責務へ分離する。

```text
UsageProvider
├── CodexUsageProvider
└── ClaudeUsageProvider

SettingsStore
├── AppearanceSettings
├── DisplaySettings
├── NotificationSettings
└── DataSourceSettings

MenuBarController
SettingsWindowController
NotificationController
LaunchAtLoginController
```

### 11.1 共通化する処理

- ステータスアイテム生成
- ポップオーバー
- フォント生成
- 色としきい値判定
- プログレスバー
- 日付・残り時間表示
- マルチモニター対応
- 更新スケジューラー
- 設定変更通知

### 11.2 設定モデル例

```text
AppearanceSettings
  fontFamily
  menuBarFontSize
  detailFontSize
  fontWeight
  useMonospacedDigits
  codexAccentColor
  claudeAccentColor
  normalColor
  cautionColor
  warningColor
  cautionThreshold
  warningThreshold
  theme

DisplaySettings
  showServiceName
  showUsageLabel
  showPercentSign
  displayRemaining
  combineServices
  menuBarTemplate
  visibleDetailFields
  detailFieldOrder

GeneralSettings
  refreshInterval
  launchAtLogin
  locale
  timeFormat

NotificationSettings
  cautionEnabled
  warningEnabled
  resetEnabled
  soundEnabled
  repeatInterval
```

色は `NSColor` をそのまま保存せず、sRGBのRGBA値へ変換して保存する。設定スキーマにはバージョンを持たせ、将来のマイグレーションに備える。

## 12. Phase 2の実装範囲

### 必須

- macOS設定ウインドウ
- `NSUserDefaults` による永続化
- フォント、サイズ、太さ
- Codex／Claudeアクセントカラー
- 通常／注意／警告カラー
- 使用率しきい値
- メニューバー表示形式
- 詳細画面の表示項目
- 更新間隔
- ログイン時自動起動
- しきい値通知
- ライブプレビュー
- 設定初期化

### 可能なら含める

- CodexとClaudeの統合表示
- ファイル監視による即時更新
- Claude `statusLine` との安全な共存と復元
- 設定のエクスポート／インポート
- 日本語／英語
- 診断画面

### Phase 3以降

- OpenAI Usage API
- Anthropic API利用量
- 日／週／月の履歴グラフ
- iCloud設定同期
- macOSウィジェット
- Homebrew Cask
- 自動アップデート
- Developer ID署名と公証
- Universal Binary
- 他のAIサービス

## 13. 開発順序

### Step 1：共通化

- 共通UIコンポーネント
- `UsageProvider`
- `SettingsStore`
- 既存動作の回帰確認

### Step 2：外観設定

- 設定ウインドウ
- フォント
- 色
- しきい値
- ライブプレビュー

### Step 3：表示設定

- メニューバーテンプレート
- 表示項目
- 使用量／残量
- 統合表示

### Step 4：一般設定

- 更新間隔
- ログイン時起動
- 言語・日時形式
- 設定リセット

### Step 5：通知と診断

- しきい値／リセット通知
- データ取得診断
- Claude `statusLine` 修復

### Step 6：品質保証

- ライト／ダークモード
- 複数ディスプレイ
- フォントサイズの上下限
- VoiceOverとキーボード操作
- 長いモデル名
- 欠損／古いデータ
- Codex／Claude未インストール環境
- CPU、メモリ、消費電力

## 14. Phase 2完了条件

- 設定画面からフォントと色を変更できる
- 変更がメニューバーと詳細画面へ即時反映される
- 再起動後も設定が維持される
- CodexとClaudeを個別に設定できる
- デフォルト設定へ安全に戻せる
- 通知が同一利用枠で重複しない
- ログイン時起動を設定できる
- 既存Claude `statusLine` を復元できる
- ライト／ダークモードで十分なコントラストを満たす
- 複数ディスプレイ機能が後退しない
- `make check` と追加テストが成功する
- READMEへ設定画面と主要設定の説明・画像を追加する

## 15. 別セッションでの開始手順

次の指示で作業を開始できる。

> `docs/PHASE2_DESIGN.md` を仕様としてPhase 2を実装してください。最初に既存のCodex版とClaude版の重複コードを共通化し、`SettingsStore` と設定ウインドウの基盤を作ってください。既存機能を維持し、各ステップで `make check` を実行してください。

最初の実装単位は「Step 1：共通化」と「Step 2の設定画面基盤」までとし、巨大な単一変更にせず段階的なPull Requestへ分けることを推奨する。
