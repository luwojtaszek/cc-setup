assert_file() { [ -f "$1" ] || { echo "missing file: $1" >&2; exit 1; }; }
assert_dir() { [ -d "$1" ] || { echo "missing dir: $1" >&2; exit 1; }; }
assert_symlink() { [ -L "$1" ] || { echo "missing symlink: $1" >&2; exit 1; }; }
assert_contains() { grep -Fq "$2" "$1" || { echo "missing text: $2" >&2; exit 1; }; }
