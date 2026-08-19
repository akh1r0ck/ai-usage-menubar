# AI Usage Menubar

CodexとClaude Codeの利用率を、macOSのメニューバーでいつでも確認できる軽量なネイティブアプリです。

`Codex 61%` / `Claude 32%` のように常時表示し、使用率に応じて緑・オレンジ・赤へ変化します。ライト／ダークモードと複数ディスプレイに対応しています。

## 特長

- Codexのサブスクリプション利用枠、リセット時刻、セッショントークンを表示
- Claude Codeのセッション枠・週間枠とリセット時刻を表示
- 5秒ごとの自動更新
- SF Pro Roundedを使ったmacOSネイティブUI
- APIキー、追加のAPI呼び出し、外部サーバーへの送信なし
- Apple Silicon搭載Mac向けのシンプルなローカルビルド

## 必要なもの

- macOS 13以降
- Xcode Command Line Tools（`xcode-select --install`）
- Codexデスクトップ／Codex CLI
- Claude版を使う場合はClaude Code

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

インストーラーは `~/.claude/settings.json` にstatusLineを設定します。既存の設定項目は保持し、別のstatusLineが設定済みの場合は `~/.claude/settings.before-claude-usage.json` にバックアップしてから置き換えます。

設定後、Claude Codeを再起動して1メッセージ送信すると利用率が表示されます。

## 複数ディスプレイ

「システム設定」→「デスクトップとDock」→「Mission Control」→「ディスプレイごとに個別の操作スペース」をオンにし、一度ログアウトしてください。各画面のメニューバーに使用率が表示されます。

## 自動起動

ビルドしたアプリを任意の場所へ移し、「システム設定」→「一般」→「ログイン項目」に追加してください。

## 開発

```sh
make build
make check
```

アプリはObjective-CとAppKitで実装しており、外部ライブラリには依存していません。生成された `.app` は `dist/` に置かれ、Gitには含まれません。

## プライバシー

処理はすべてMac内で完結します。会話本文の表示、保存、外部送信は行いません。Codex版は利用量イベント、Claude版はstatusLineから受け取った利用率情報だけを使用します。

## 注意事項

このプロジェクトは非公式であり、OpenAIおよびAnthropicとは提携していません。各製品のローカルデータ形式やstatusLine仕様の変更により、表示できなくなる可能性があります。

## License

[MIT License](LICENSE)
