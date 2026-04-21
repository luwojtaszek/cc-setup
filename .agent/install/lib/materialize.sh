#!/usr/bin/env bash

copy_dir_atomic() {
  local source="$1"
  local target="$2"
  local parent
  local base
  local tmp
  local backup

  [ -d "$source" ] || fail "missing source dir: $source"

  parent="$(dirname "$target")"
  base="$(basename "$target")"
  tmp="$parent/.${base}.tmp.$$"
  backup="$parent/.${base}.old.$$"

  if [ "$DRY_RUN" = true ]; then
    echo "Would copy $source -> $target"
    return
  fi

  mkdir -p "$parent"
  rm -rf "$tmp" "$backup"
  mkdir -p "$tmp"
  cp -R "$source"/. "$tmp"/

  if [ -e "$target" ] || [ -L "$target" ]; then
    mv "$target" "$backup"
    if ! mv "$tmp" "$target"; then
      mv "$backup" "$target"
      fail "failed to replace $target"
    fi
    rm -rf "$backup"
    return
  fi

  mv "$tmp" "$target"
}
