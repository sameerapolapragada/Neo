#!/bin/bash
# Builds a temporary ios/ project on the EAS worker. The checked-in project stays at Neo.xcodeproj.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

python3 - <<'PY'
import base64
import json
import os
import sys

url = os.environ.get("SUPABASE_URL", "").strip().rstrip("/")
key = os.environ.get("SUPABASE_ANON_KEY", "")
expected = "https://hsfbuaefataujdzglexm.supabase.co"

if not url or not key:
    sys.exit("SUPABASE_URL and SUPABASE_ANON_KEY must be set on the EAS worker.")
if url != expected:
    sys.exit("SUPABASE_URL is not the Neo project.")
if any(character in key for character in ("\n", "\r", " ", "\t", "#", "/", "$", '"', "'")):
    sys.exit("SUPABASE_ANON_KEY contains characters that are unsafe in an xcconfig.")

lower = key.lower()
if lower.startswith("sb_secret") or "service_role" in lower:
    sys.exit("Refusing a service-role credential.")

parts = key.split(".")
if len(parts) == 3:
    payload = parts[1] + "=" * (-len(parts[1]) % 4)
    try:
        data = json.loads(base64.urlsafe_b64decode(payload))
    except Exception:
        data = {}
    if data.get("role") == "service_role":
        sys.exit("Refusing a service-role credential.")
PY

OUT="${SUPABASE_XCCONFIG_PATH:-$ROOT/Config/Secrets.xcconfig}"
umask 077
tmp="$(mktemp)"
{
  echo "// Generated on the EAS builder. Do not commit."
  echo "SLASH = /"
  echo 'SUPABASE_URL = https:$(SLASH)/hsfbuaefataujdzglexm.supabase.co'
  printf 'SUPABASE_ANON_KEY = %s\n' "$SUPABASE_ANON_KEY"
} > "$tmp"
mv "$tmp" "$OUT"
chmod 600 "$OUT"

rm -rf "$ROOT/ios/Neo.xcodeproj"
mkdir -p "$ROOT/ios"
cp -R "$ROOT/Neo.xcodeproj" "$ROOT/ios/Neo.xcodeproj"

python3 - <<'PY'
from pathlib import Path
path = Path("ios/Neo.xcodeproj/project.pbxproj")
text = path.read_text()
replacements = {
    "path = Config/Shared.xcconfig;": "path = ../Config/Shared.xcconfig;",
    "path = Neo;": "path = ../Neo;",
    "path = NeoTests;": "path = ../NeoTests;",
    "INFOPLIST_FILE = Info.plist;": "INFOPLIST_FILE = ../Info.plist;",
}
for old, new in replacements.items():
    count = text.count(old)
    if count == 0:
        raise SystemExit(f"Expected to rewrite {old}")
    text = text.replace(old, new)
path.write_text(text)
PY
