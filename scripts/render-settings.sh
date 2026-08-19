#!/bin/sh
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
clang -fobjc-arc -fblocks -framework Cocoa -framework ServiceManagement -framework UserNotifications -framework UniformTypeIdentifiers -I "$PROJECT_DIR/Sources" "$PROJECT_DIR/Sources/render_settings.m" "$PROJECT_DIR/Sources/UsageUI.m" -o "$TEMP_DIR/render-settings"
AI_USAGE_DEFAULTS_SUITE="jp.local.ai-usage.render.light.$$" "$TEMP_DIR/render-settings" "$PROJECT_DIR/docs/images/settings-window.png" light
AI_USAGE_DEFAULTS_SUITE="jp.local.ai-usage.render.dark.$$" "$TEMP_DIR/render-settings" "$PROJECT_DIR/docs/images/settings-window-dark.png" dark
