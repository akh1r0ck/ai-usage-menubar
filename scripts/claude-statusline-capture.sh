#!/bin/sh
set -eu

INPUT=$(cat)
CACHE="$HOME/.claude/usage-menubar.json"
TMP="$CACHE.tmp"
printf '%s\n' "$INPUT" > "$TMP"
mv "$TMP" "$CACHE"

/usr/bin/python3 -c '
import json, sys
try:
    d=json.load(sys.stdin); r=d.get("rate_limits") or {}
    p=r.get("five_hour") or r.get("session") or {}
    w=r.get("seven_day") or r.get("week") or {}
    a=[]
    if p.get("used_percentage") is not None: a.append("session %.0f%%" % p["used_percentage"])
    if w.get("used_percentage") is not None: a.append("week %.0f%%" % w["used_percentage"])
    print(" | ".join(a))
except Exception: pass
' <<EOF
$INPUT
EOF
