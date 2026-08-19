#!/bin/sh
set -eu

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
export AI_USAGE_DEFAULTS_SUITE="jp.local.ai-usage.tests.$$"
clang -fobjc-arc -fblocks -framework Cocoa -framework ServiceManagement -framework UserNotifications -framework UniformTypeIdentifiers -I Sources Sources/settings_test.m Sources/UsageUI.m -o "$TEST_DIR/settings-test"
"$TEST_DIR/settings-test"
