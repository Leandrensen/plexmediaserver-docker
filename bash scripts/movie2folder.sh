#!/bin/bash

set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

shopt -s nullglob nocaseglob
for file in *.mkv *.mp4 *.wmv *.avi; do
  if [[ -f "$file" ]]; then
    dirname="${file%.*}"
    if [[ -n "$dirname" ]]; then
      mkdir -p "$dirname"
      mv -n "$file" "$dirname/"
      echo "Moved: $file -> $dirname/"
    else
      echo "Skipping unexpected file name: $file" >&2
    fi
  fi
done