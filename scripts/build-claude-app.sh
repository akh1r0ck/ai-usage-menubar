#!/bin/sh
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_DIR="$PROJECT_DIR/dist/Claude Usage.app"
CONTENTS="$APP_DIR/Contents"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
clang -fobjc-arc -fblocks -framework Cocoa -O2 "$PROJECT_DIR/Sources/claude_main.m" -o "$CONTENTS/MacOS/ClaudeUsage"
cp "$PROJECT_DIR/Resources/ClaudeInfo.plist" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"
echo "作成しました: $APP_DIR"
