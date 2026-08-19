#!/bin/sh
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_BINARY=$(mktemp "${TMPDIR:-/tmp}/claude-usage-test.XXXXXX")
trap 'rm -f "$TEST_BINARY"' EXIT
clang -fobjc-arc -fblocks -framework Foundation "$PROJECT_DIR/Sources/claude_usage_test.m" "$PROJECT_DIR/Sources/ClaudeUsage.m" -o "$TEST_BINARY"
"$TEST_BINARY"
