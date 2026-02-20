#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TARGET_DIR="asterisk_etc"
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "ERROR: Directory not found: $TARGET_DIR" >&2
  exit 1
fi

mapfile -t files < <(find "$TARGET_DIR" -type f \( -name '*.conf' -o -name '*.md' \) | sort)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "WARN: No .conf/.md files found under $TARGET_DIR"
  exit 0
fi

errors=0

for file in "${files[@]}"; do
  if LC_ALL=C grep -n '[^ -~\t\r\n]' "$file" >/dev/null; then
    echo "ERROR: Non-ASCII character(s) found in $file"
    LC_ALL=C grep -n '[^ -~\t\r\n]' "$file" | head -n 5
    errors=$((errors + 1))
  fi
done

if (( errors > 0 )); then
  echo "Encoding check failed with ${errors} file(s) containing non-ASCII characters." >&2
  exit 1
fi

echo "Encoding check OK: all ${#files[@]} file(s) in $TARGET_DIR are ASCII-safe."
