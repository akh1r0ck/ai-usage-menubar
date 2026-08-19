# Phase 1 Spin-off — Claude二重利用枠表示 設計書

## 1. 位置づけ

本設計はPhase 2の設定・カスタマイズ開発とは分離し、Phase 1のスピンオフとして実装する。

対象はClaudeの以下2つの利用枠を、現在のmacOSメニューバーアプリで見やすく表示することに限定する。

- 短期のセッション利用枠
- 週間利用枠

フォント選択、カラーピッカー、設定ウインドウ、通知などは本スピンオフへ含めない。それらは `docs/PHASE2_DESIGN.md` で扱う。

## 2. 背景

Claudeの利用枠はセッションと週間で独立している。一方だけを表示すると、セッション枠に余裕があっても週間枠が上限に近い状態を見落とす可能性がある。

そのため、メニューバーでは常に両方を識別できるようにし、詳細画面では独立したカードとして表示する。

Claude Desktop、Claude Web、Claude Codeの利用量は同じ利用枠へ合算される。取得元がClaude Codeの `statusLine` であっても、表示する値の意味はClaude全体の共有利用枠である。

## 3. スコープ

### 3.1 実装対象

- セッション使用率の表示
- 週間使用率の表示
- 各利用枠の個別カラー判定
- 各利用枠のリセット日時
- リセットまでの相対時間
- 片方のデータが欠けた場合の表示
- データ鮮度と最終更新時刻
- 取得元と共有利用枠であることの説明
- VoiceOver向けの状態説明

### 3.2 対象外

- Claude Desktopの非公開APIへの接続
- Claude Desktopの認証情報の読み取り
- フォントや色の設定画面
- 任意のしきい値設定
- 通知機能
- 履歴グラフ
- OpenAI／Anthropic API課金額
- Codex版のUI変更
- CodexとClaudeの統合メニューバー

## 4. 用語

| 内部名称 | UI表示 | 意味 |
|---|---|---|
| `session` | セッション | 主に短期・5時間単位の利用枠 |
| `weekly` | 週間 | 主に7日単位の利用枠 |

取得元の `primary`、`secondary`、`five_hour`、`seven_day` といった名称はUIへ直接表示しない。

## 5. メニューバー

### 5.1 デフォルト表示

```text
Claude 32% · W78%
```

- ラベルのない最初の数値をセッション使用率とする
- `W`付きの数値を週間使用率とする
- 数値ごとに独立した色を適用する
- Claudeのブランド表示は既存の紫色を維持する

### 5.2 表示例

```text
Claude 32% · W45%
Claude 72% · W45%
Claude 32% · W88%
Claude 92% · W94%
```

### 5.3 カラー判定

既存のPhase 1基準を両方の利用枠へ個別に適用する。

| 使用率 | 色 | 状態 |
|---:|---|---|
| 0〜59% | 緑 | 余裕あり |
| 60〜84% | オレンジ | 注意 |
| 85〜100% | 赤 | 上限間近 |

アプリ全体の危険度が必要な場合は、セッションと週間のうち高い方を採用する。ただし各数値の色は必ず個別判定する。

### 5.4 欠損状態

片方の値を取得できない場合でも、項目自体を消さない。

```text
Claude 32% · W--%
Claude --% · W78%
Claude --% · W--%
```

これにより、値が0%なのか取得できていないのかを区別する。

### 5.5 古いデータ

最終更新から10分以上経過した場合は警告記号を付ける。

```text
Claude 32% · W78% ⚠
```

古い値を消去せず、直前の値を維持しながら鮮度警告を表示する。

## 6. 詳細ポップオーバー

セッションと週間を上下の独立カードとして表示する。

```text
┌──────────────────────────────────┐
│ Claude 使用量                    │
│ Pro                        更新 ↻│
│                                  │
│ セッション                       │
│ 32% 使用                 残り68% │
│ ██████░░░░░░░░░░░░              │
│ あと2時間14分                    │
│ 8月19日 23:00 にリセット         │
│                                  │
│ 週間                             │
│ 78% 使用                 残り22% │
│ ███████████████░░░░░             │
│ あと2日6時間                     │
│ 8月22日 7:00 にリセット          │
│                                  │
│ 最終更新：21:42:18               │
│ Claude Desktop・Web・Codeの合算  │
│ 取得元：Claude Code statusLine   │
│                                  │
│                          ［終了］│
└──────────────────────────────────┘
```

### 6.1 情報の優先順位

各カードでは次の順番で表示する。

1. 利用枠名
2. 使用率と残量
3. プログレスバー
4. リセットまでの残り時間
5. 正確なリセット日時

### 6.2 カードの状態

- 通常：標準背景と緑色のバー
- 注意：オレンジ色のバー
- 上限間近：赤色のバー
- データ欠損：バーを無効表示し「取得できません」
- 古いデータ：値を維持し警告テキストを表示
- 上限到達：「利用枠のリセット待ち」を表示

## 7. リセット時間

相対時間と絶対時間を併記する。

```text
あと2時間14分
8月19日 23:00 にリセット
```

表示規則：

| 状態 | 表示 |
|---|---|
| 1分未満 | まもなくリセット |
| 1時間未満 | あと42分 |
| 24時間未満 | あと2時間14分 |
| 24時間以上 | あと2日6時間 |
| 時刻不明 | リセット時刻を取得できません |
| 時刻超過 | データを再取得中 |

日時はユーザーのローカルタイムゾーンを使用する。

## 8. データモデル

```text
ClaudeUsageWindow
  kind
    session
    weekly

  usedPercent: Double?
  remainingPercent: Double?
  windowMinutes: Int?
  resetsAt: Date?
  fetchedAt: Date
  source: String
  isStale: Bool
```

スナップショット：

```text
ClaudeUsageSnapshot
  sessionWindow: ClaudeUsageWindow?
  weeklyWindow: ClaudeUsageWindow?
  planType: String?
  modelName: String?
  fetchedAt: Date
  source: ClaudeUsageSource
```

取得元：

```text
ClaudeUsageSource
  claudeCodeStatusLine
  cache
  unavailable
```

## 9. 利用枠の分類

取得データで利用枠種別が明示されている場合は、その値を優先する。

対応するキー：

```text
session
five_hour
current_session

weekly
week
seven_day
current_week
```

種別が明示されていない場合は `window_minutes` を利用する。

```text
期間が短い方 → session
期間が長い方 → weekly
```

期間を5時間・7日に固定しない。将来的に利用枠期間が変更されても、取得データに追従できるようにする。

## 10. データ鮮度

| 最終更新からの経過 | 状態 |
|---:|---|
| 1分未満 | 最新 |
| 1〜10分 | 通常 |
| 10〜30分 | やや古い |
| 30分以上 | 古い |
| 取得不能 | 利用不可 |

詳細画面では最終更新時刻を常に表示する。

```text
最終更新：42分前 ⚠
現在の使用率と異なる可能性があります
```

## 11. 取得元の説明

詳細画面の下部に次を表示する。

```text
Claude Desktop・Web・Claude Codeの利用量を合算した共有利用枠です
取得元：Claude Code statusLine
```

本スピンオフではClaude Desktopの内部ストレージや非公開APIへアクセスしない。

## 12. エラー表示

### 12.1 全データなし

```text
利用量データを取得できません

Claude Codeを起動して1メッセージ送信すると、
共有利用枠が表示されます。

［再取得］
```

### 12.2 セッションのみ取得

セッションカードは通常表示し、週間カードを無効状態で残す。

```text
週間
使用率を取得できません
```

### 12.3 週間のみ取得

週間カードは通常表示し、セッションカードを無効状態で残す。

### 12.4 上限到達

```text
100%使用
利用枠のリセット待ち
あと38分
```

## 13. アクセシビリティ

色だけで状態を表現しない。

- 緑：余裕あり
- オレンジ：注意
- 赤：上限間近
- データなし：取得できません
- 古いデータ：警告記号と説明

VoiceOverの読み上げ例：

```text
Claudeセッション使用率32パーセント、余裕あり、リセットまで2時間14分
```

```text
Claude週間使用率78パーセント、注意、リセットまで2日6時間
```

## 14. 実装対象ファイルの想定

現行構成を維持する場合：

```text
Sources/claude_main.m
scripts/claude-statusline-capture.sh
Resources/ClaudeInfo.plist
README.md
```

データモデルと表示ロジックを分離する場合：

```text
Sources/Claude/ClaudeUsageModel.h
Sources/Claude/ClaudeUsageModel.m
Sources/Claude/ClaudeUsageParser.h
Sources/Claude/ClaudeUsageParser.m
Sources/Claude/ClaudeMenuBarController.h
Sources/Claude/ClaudeMenuBarController.m
Sources/Claude/ClaudePopoverController.h
Sources/Claude/ClaudePopoverController.m
```

Phase 2の共通化前であるため、大規模な共通基盤の導入は避ける。ただしパーサーとUIの分離は行い、後からPhase 2へ移行しやすくする。

## 15. テスト項目

### 15.1 パーサー

- `five_hour` と `seven_day`
- `session` と `week`
- `current_session` と `current_week`
- `primary` と `secondary` ＋ `window_minutes`
- セッションのみ
- 週間のみ
- 両方なし
- 不正なJSON
- 0%、59%、60%、84%、85%、100%
- 秒／ミリ秒のリセット時刻

### 15.2 UI

- 通常状態
- セッションのみ注意
- 週間のみ警告
- 両方警告
- 上限到達
- データ欠損
- 古いデータ
- ライト／ダークモード
- 複数ディスプレイ
- 長いプラン名／モデル名
- VoiceOver

### 15.3 回帰確認

- Claude使用率アプリが従来どおり起動する
- statusLine中継スクリプトが動作する
- Codex版へ影響しない
- `make check` が成功する

## 16. 受け入れ条件

- メニューバーでセッションと週間を同時に識別できる
- セッションと週間が個別の色で表示される
- 詳細画面で2つが独立したカードとして表示される
- 両方のリセット日時と残り時間を確認できる
- 一方の値が欠けても、もう一方を表示できる
- データ欠損を0%として扱わない
- 期間を5時間・7日に固定しない
- 古いデータを最新データと同じ見た目で表示しない
- 取得元と共有利用枠であることを確認できる
- 色を識別できなくても状態を理解できる
- Codex版へ変更を加えない
- `make check` が成功する

## 17. 推奨ブランチと開発単位

推奨ブランチ名：

```text
codex/claude-dual-usage-windows
```

推奨コミット単位：

1. Claude利用枠モデルとパーサー
2. セッション・週間のメニューバー表示
3. 二段カードの詳細画面
4. データ鮮度・エラー・アクセシビリティ
5. テストとREADME更新

## 18. 別セッションでの開始指示

以下を別セッションへ渡して開発を開始できる。

> `docs/PHASE1_SPINOFF_CLAUDE_DUAL_LIMITS.md` を仕様として、Phase 1スピンオフを実装してください。新しく `codex/claude-dual-usage-windows` ブランチを作成し、最初にClaude利用枠のモデルとパーサーをUIから分離してください。Claude CodeのstatusLineを取得元として維持し、セッションと週間を個別表示してください。Codex版には変更を加えず、各段階で `make check` を実行してください。
