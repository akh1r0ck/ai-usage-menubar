#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_DIR="$PROJECT_DIR/dist/ChatGPT Usage.app"
STAGING_DIR=$(mktemp -d)
trap 'rm -rf "$STAGING_DIR"' EXIT
STAGING_APP="$STAGING_DIR/ChatGPT Usage.app"
CONTENTS="$STAGING_APP/Contents"

cd "$PROJECT_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
clang -fobjc-arc -fblocks -framework Cocoa -framework ServiceManagement -framework UserNotifications -framework UniformTypeIdentifiers -O2 "Sources/main.m" "Sources/UsageUI.m" "Sources/UsageProvider.m" "Sources/ClaudeUsage.m" -o "$CONTENTS/MacOS/ChatGPTUsage"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"
xattr -cr "$STAGING_APP"
codesign --force --sign - "$STAGING_APP"
rm -rf "$APP_DIR"
mv "$STAGING_APP" "$APP_DIR"
echo "作成しました: $APP_DIR"
