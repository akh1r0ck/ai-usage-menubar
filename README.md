# AI Usage Menubar

<p align="center">
  <img src="docs/images/ai-usage-menubar-hero.png" alt="CodexとClaude Codeの利用率を表示するmacOSメニューバーアプリの画面イメージ" width="100%">
</p>

<p align="center">
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-111827?logo=apple&logoColor=white">
  <img alt="Objective-C" src="https://img.shields.io/badge/Objective--C-AppKit-2563EB?logo=apple&logoColor=white">
  <img alt="No API key required" src="https://img.shields.io/badge/API_key-not_required-16A34A">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-7C3AED"></a>
</p>

CodexとClaude Codeの利用率を、macOSのメニューバーでいつでも確認できる軽量なネイティブアプリです。

`Codex 61%` / `Claude 32%` のように常時表示し、使用率に応じて緑・オレンジ・赤へ変化します。ライト／ダークモードと複数ディスプレイに対応しています。

> 上の画像は実装をもとにした画面イメージです。表示される使用率・期間・モデル名はアカウントと利用状況によって変わります。

## ひと目で分かること

| | Codex | Claude Code |
|---|---|---|
| メニューバー | `Codex 61%` | `Claude 32%` |
| 利用枠 | サブスクリプション枠 | セッション枠・週間枠 |
| 詳細 | リセット時刻、累計トークン、文脈使用率 | リセット時刻、使用モデル |
| データ取得 | ローカルの`token_count`イベント | Claude Codeの`statusLine` |
| 追加API通信 | なし | なし |

## 特長

- Codexのサブスクリプション利用枠、リセット時刻、セッショントークンを表示
- Claude Codeのセッション枠・週間枠とリセット時刻を表示
- 1秒〜1分から選べる自動更新
- フォント、文字サイズ、配色、しきい値を変更できるmacOS設定画面
- 使用量／残量、サービス名、詳細項目を個別に表示設定
- 注意・警告しきい値の重複しない通知
- APIキー、追加のAPI呼び出し、外部サーバーへの送信なし
- Apple Silicon搭載Mac向けのシンプルなローカルビルド

## 必要なもの

- macOS 13以降
- Xcode Command Line Tools（`xcode-select --install`）
- Codexデスクトップ／Codex CLI
- Claude版を使う場合はClaude Code

## クイックスタート

リポジトリを取得し、両方のアプリをビルドします。

```sh
git clone https://github.com/akh1r0ck/ai-usage-menubar.git
cd ai-usage-menubar
make build
```

ビルド結果は `dist/ChatGPT Usage.app` と `dist/Claude Usage.app` に作成されます。

## Codex版

```sh
./scripts/build-app.sh
open "dist/ChatGPT Usage.app"
```

Codexが `~/.codex/sessions/**/*.jsonl` に記録する `token_count` イベントだけを読み取ります。通常のChatGPT Web／ChatGPTアプリ全体の使用量を表示するものではありません。

## Claude Code版

```sh
./scripts/build-claude-app.sh
python3 scripts/install-claude-capture.py
open "dist/Claude Usage.app"
```

インストーラーは `~/.claude/settings.json` にstatusLineを設定します。既存の設定項目は保持して置き換えます。

既存のstatusLineがある場合はその項目だけを`~/.claude/usage-menubar-statusline-backup.json`へ保存します。元へ戻すには次を実行します。他のClaude Code設定は維持されます。

```sh
python3 scripts/restore-claude-statusline.py
```

設定後、Claude Codeを再起動して1メッセージ送信すると利用率が表示されます。

Claude版はメニューバーに `Claude 32% · W78%` の形式で、短期のセッション枠と週間枠を同時に表示します。各数値は使用率に応じて個別に色分けされ、一方を取得できない場合は `--%` のまま残ります。クリックすると、両方の残量、リセットまでの時間、正確なリセット日時、データの最終更新時刻を確認できます。10分以上更新されていない値には `⚠` が付きます。

## 仕組み

```mermaid
flowchart LR
    Codex["Codex Desktop / CLI"] -->|"token_count"| CodexLog["~/.codex/sessions"]
    CodexLog --> CodexApp["Codex Usage Menubar"]
    Claude["Claude Code"] -->|"statusLine JSON"| Capture["ローカル中継スクリプト"]
    Capture --> ClaudeCache["~/.claude/usage-menubar.json"]
    ClaudeCache --> ClaudeApp["Claude Usage Menubar"]
    CodexApp --> MenuBar["macOS メニューバー"]
    ClaudeApp --> MenuBar
```

どちらも読み取りと表示はMac内で完結します。利用量を確認するための追加APIリクエストは発生しません。

## 色の見方

| 使用率 | 色 | 状態 |
|---:|:---:|---|
| 0–59% | 🟢 | 余裕あり |
| 60–84% | 🟠 | 残量に注意 |
| 85–100% | 🔴 | 上限が近い |

## 複数ディスプレイ

「システム設定」→「デスクトップとDock」→「Mission Control」→「ディスプレイごとに個別の操作スペース」をオンにし、一度ログアウトしてください。各画面のメニューバーに使用率が表示されます。

## 設定

メニューバーの利用率をクリックし、「設定…」を選びます。設定は変更時にすぐ反映され、アプリを終了しても維持されます。

![外観設定画面](docs/images/settings-window.png)

- 一般：更新間隔、Macログイン時の自動起動
- 外観：フォント、サイズ、太さ、等幅数字、アクセントと状態色、使用率しきい値
- 表示項目：サービス名、使用量／残量、%記号、詳細画面の各項目
- 通知：注意・警告しきい値への到達通知（同じ利用枠では一度だけ）
- データ／詳細：読み取るデータとプライバシー情報

外観・表示・通知などの共通設定はCodex版とClaude版で共有され、どちらかで変更すると両方へ反映されます。「データ」タブからJSON形式で設定を書き出し／読み込みでき、データフォルダの表示や機密情報を含まない診断情報のコピーもできます。

ログイン時起動を利用する場合は、ビルドしたアプリを`/Applications`へ移動してから有効にしてください。

## 開発

```sh
make build
make check
```

アプリはObjective-CとAppKitで実装しており、外部ライブラリには依存していません。生成された `.app` は `dist/` に置かれ、Gitには含まれません。

設定・カスタマイズ機能の設計については、[Phase 2設計書](docs/PHASE2_DESIGN.md)を参照してください。

### プロジェクト構成

```text
.
├── Sources/       # Codex版・Claude版のAppKit実装
├── Resources/     # 各アプリのInfo.plist
├── scripts/       # ビルドとClaude statusLine設定
├── docs/images/   # README用画像
├── Makefile
└── README.md
```

## プライバシー

処理はすべてMac内で完結します。会話本文の表示、保存、外部送信は行いません。Codex版は利用量イベント、Claude版はstatusLineから受け取った利用率情報だけを使用します。

## 注意事項

このプロジェクトは非公式であり、OpenAIおよびAnthropicとは提携していません。各製品のローカルデータ形式やstatusLine仕様の変更により、表示できなくなる可能性があります。

## License

[MIT License](LICENSE)
