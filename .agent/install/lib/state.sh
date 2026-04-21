#!/usr/bin/env bash

state_file() {
  printf '%s\n' "$HOME/.config/cc-setup/state.json"
}

read_state_hash() {
  python3 - "$(state_file)" "$1" <<'PY'
from pathlib import Path
import json
import sys

state_path = Path(sys.argv[1])
target = sys.argv[2]
if not state_path.exists():
    raise SystemExit(0)

data = json.loads(state_path.read_text())
entry = data.get("items", {}).get(target)
if entry:
    print(entry.get("contentHash", ""))
PY
}

record_state() {
  local target="$1"
  local source="$2"
  local method="$3"
  local hash="$4"
  local file
  file="$(state_file)"
  mkdir -p "$(dirname "$file")"

  python3 - "$file" "$target" "$source" "$method" "$hash" <<'PY'
from datetime import datetime, timezone
from pathlib import Path
import json
import os
import sys
import tempfile

state_path = Path(sys.argv[1])
target = sys.argv[2]
source = sys.argv[3]
method = sys.argv[4]
content_hash = sys.argv[5]

if state_path.exists():
    data = json.loads(state_path.read_text())
else:
    data = {}

items = data.setdefault("items", {})
items[target] = {
    "targetPath": target,
    "sourceIdentifier": source,
    "installMethod": method,
    "contentHash": content_hash,
    "installedAt": datetime.now(timezone.utc).isoformat(),
}

state_path.parent.mkdir(parents=True, exist_ok=True)
fd, tmp_name = tempfile.mkstemp(prefix=state_path.name, dir=state_path.parent)
with os.fdopen(fd, "w") as tmp:
    json.dump(data, tmp, indent=2, sort_keys=True)
    tmp.write("\n")
os.replace(tmp_name, state_path)
PY
}
