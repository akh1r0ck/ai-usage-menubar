#!/bin/sh
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
APP_DIR="$PROJECT_DIR/dist/Claude Usage.app"
STAGING_DIR=$(mktemp -d)
trap 'rm -rf "$STAGING_DIR"' EXIT
STAGING_APP="$STAGING_DIR/Claude Usage.app"
CONTENTS="$STAGING_APP/Contents"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
clang -fobjc-arc -fblocks -framework Cocoa -framework ServiceManagement -framework UserNotifications -framework UniformTypeIdentifiers -O2 "$PROJECT_DIR/Sources/claude_main.m" "$PROJECT_DIR/Sources/ClaudeUsage.m" "$PROJECT_DIR/Sources/UsageUI.m" "$PROJECT_DIR/Sources/UsageProvider.m" -o "$CONTENTS/MacOS/ClaudeUsage"
cp "$PROJECT_DIR/Resources/ClaudeInfo.plist" "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"
xattr -cr "$STAGING_APP"
codesign --force --sign - "$STAGING_APP"
rm -rf "$APP_DIR"
mv "$STAGING_APP" "$APP_DIR"
echo "作成しました: $APP_DIR"
