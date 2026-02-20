#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION_FILE="$ROOT_DIR/VERSION"
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "ERROR: VERSION file not found." >&2
  exit 1
fi

EXPECTED="$(tr -d ' \t\r\n' < "$VERSION_FILE")"
if [[ -z "$EXPECTED" ]]; then
  echo "ERROR: VERSION file is empty." >&2
  exit 1
fi

errors=0

check_contains() {
  local file="$1"
  local pattern="$2"

  if [[ ! -f "$file" ]]; then
    echo "WARN: Skipping missing file: $file"
    return 0
  fi

  if ! grep -Eq -- "$pattern" "$file"; then
    echo "ERROR: Version mismatch in $file"
    errors=$((errors + 1))
  fi
}

check_contains "asterisk_etc/extensions.conf" "MAGNUS_VERSION=${EXPECTED}"
check_contains "docker-compose.optimized.yml" "# Vers(ao|ão): ${EXPECTED}"
check_contains "sql/01_init_schema.sql" "-- Vers(ao|ão): ${EXPECTED}"
check_contains "sql/02_sample_data.sql" "-- Vers(ao|ão): ${EXPECTED}"

if (( errors > 0 )); then
  echo "Version check failed with ${errors} error(s)." >&2
  exit 1
fi

echo "Version check OK (${EXPECTED})."
