#!/bin/sh
set -eu
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
clang -fobjc-arc -fblocks -framework Foundation -I Sources Sources/provider_test.m Sources/UsageProvider.m Sources/ClaudeUsage.m -o "$TEST_DIR/provider-test"
"$TEST_DIR/provider-test"
