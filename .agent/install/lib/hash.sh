#!/usr/bin/env bash

hash_path() {
  python3 - "$1" <<'PY'
from pathlib import Path
import hashlib
import sys

root = Path(sys.argv[1])
h = hashlib.sha256()
for path in sorted(root.rglob("*")):
    rel = path.relative_to(root).as_posix().encode()
    h.update(rel)
    if path.is_file():
        h.update(path.read_bytes())
print(h.hexdigest())
PY
}
