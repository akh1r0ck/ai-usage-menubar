#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_DIR="$PROJECT_DIR/dist/ChatGPT Usage.app"
CONTENTS="$APP_DIR/Contents"

cd "$PROJECT_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
clang -fobjc-arc -fblocks -framework Cocoa -O2 "Sources/main.m" -o "$CONTENTS/MacOS/ChatGPTUsage"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"
echo "作成しました: $APP_DIR"
