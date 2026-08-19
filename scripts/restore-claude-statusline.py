#!/usr/bin/env python3
import json
import os
from pathlib import Path

claude = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
settings_path = claude / "settings.json"
backup_path = claude / "usage-menubar-statusline-backup.json"
target = claude / "claude-usage-capture.sh"

if not settings_path.exists():
    raise SystemExit("Claude Codeのsettings.jsonが見つかりません。")

settings = json.loads(settings_path.read_text())
current = settings.get("statusLine")
if not isinstance(current, dict) or current.get("command") != str(target):
    raise SystemExit("statusLineはAI Usage Menubarの設定ではないため変更しませんでした。")

if backup_path.exists():
    backup = json.loads(backup_path.read_text())
    settings["statusLine"] = backup["statusLine"]
else:
    settings.pop("statusLine", None)

temporary = settings_path.with_suffix(".json.tmp")
temporary.write_text(json.dumps(settings, ensure_ascii=False, indent=2) + "\n")
os.replace(temporary, settings_path)
backup_path.unlink(missing_ok=True)
print("Claude Codeの元のstatusLineを復元しました。")
