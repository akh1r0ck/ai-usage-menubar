#!/bin/sh
set -eu

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT
export CLAUDE_CONFIG_DIR="$TEST_DIR/.claude"
mkdir -p "$CLAUDE_CONFIG_DIR"
printf '%s\n' '{"theme":"dark","statusLine":{"type":"command","command":"original-command"}}' > "$CLAUDE_CONFIG_DIR/settings.json"

python3 scripts/install-claude-capture.py >/dev/null
python3 -c 'import json, os; from pathlib import Path; d=json.loads((Path(os.environ["CLAUDE_CONFIG_DIR"])/"settings.json").read_text()); assert d["theme"]=="dark"; assert d["statusLine"]["command"].endswith("claude-usage-capture.sh")'
python3 scripts/restore-claude-statusline.py >/dev/null
python3 -c 'import json, os; from pathlib import Path; d=json.loads((Path(os.environ["CLAUDE_CONFIG_DIR"])/"settings.json").read_text()); assert d=={"theme":"dark","statusLine":{"type":"command","command":"original-command"}}'
