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
    p=r.get("five_hour") or r.get("session") or r.get("current_session") or {}
    w=r.get("seven_day") or r.get("weekly") or r.get("week") or r.get("current_week") or {}
    a=[]
    pv=next((p.get(k) for k in ("used_percentage","percentage","used_percent","used") if p.get(k) is not None),None)
    wv=next((w.get(k) for k in ("used_percentage","percentage","used_percent","used") if w.get(k) is not None),None)
    if pv is not None: a.append("session %.0f%%" % pv)
    if wv is not None: a.append("week %.0f%%" % wv)
    print(" | ".join(a))
except Exception: pass
' <<EOF
$INPUT
EOF
