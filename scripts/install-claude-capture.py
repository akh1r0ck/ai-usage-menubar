#!/usr/bin/env python3
import json
import os
import shutil
from pathlib import Path

project = Path(__file__).resolve().parent.parent
claude = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
claude.mkdir(exist_ok=True)
target = claude / "claude-usage-capture.sh"
shutil.copy2(project / "scripts" / "claude-statusline-capture.sh", target)
target.chmod(0o755)

settings_path = claude / "settings.json"
try:
    settings = json.loads(settings_path.read_text()) if settings_path.exists() else {}
except json.JSONDecodeError as exc:
    raise SystemExit(f"settings.jsonを解析できません: {exc}")

existing = settings.get("statusLine")
if existing and existing.get("command") != str(target):
    backup = claude / "usage-menubar-statusline-backup.json"
    if not backup.exists():
        backup.write_text(json.dumps({"statusLine": existing}, ensure_ascii=False, indent=2) + "\n")

settings["statusLine"] = {"type": "command", "command": str(target)}
temporary = settings_path.with_suffix(".json.tmp")
temporary.write_text(json.dumps(settings, ensure_ascii=False, indent=2) + "\n")
os.replace(temporary, settings_path)
print(f"Claude Code statusLineを設定しました: {target}")
