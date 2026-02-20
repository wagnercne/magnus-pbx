#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TARGET_DIR="asterisk_etc"
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "ERROR: Directory not found: $TARGET_DIR" >&2
  exit 1
fi

usage() {
  cat <<'EOF'
Usage: ./scripts/check-encoding-asterisk.sh [--mojibake|--strict-active|--strict-all]

Modes:
  --mojibake      Check for broken encoding artifacts only (Ã, Â, �). [default]
  --strict-active Check for any non-ASCII chars only in active dialplan/config files.
  --strict-all    Check for any non-ASCII chars in all .conf/.md under asterisk_etc.
EOF
}

MODE="mojibake"
if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

if [[ $# -eq 1 ]]; then
  case "$1" in
    --mojibake) MODE="mojibake" ;;
    --strict-active) MODE="strict-active" ;;
    --strict-all) MODE="strict-all" ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "ERROR: Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
fi

mapfile -t all_files < <(find "$TARGET_DIR" -type f \( -name '*.conf' -o -name '*.md' \) | sort)

active_files=(
  "asterisk_etc/extensions.conf"
  "asterisk_etc/extensions_additional.conf"
  "asterisk_etc/extensions_custom.conf"
  "asterisk_etc/extensions-features.conf"
  "asterisk_etc/routing.conf"
  "asterisk_etc/tenants.conf"
  "asterisk_etc/features.conf"
  "asterisk_etc/features_general_additional.conf"
  "asterisk_etc/features_general_custom.conf"
  "asterisk_etc/features_featuremap_additional.conf"
  "asterisk_etc/features_featuremap_custom.conf"
  "asterisk_etc/features_applicationmap_additional.conf"
  "asterisk_etc/features_applicationmap_custom.conf"
  "asterisk_etc/extconfig.conf"
  "asterisk_etc/sorcery.conf"
  "asterisk_etc/pjsip.conf"
  "asterisk_etc/modules.conf"
)

files=()
case "$MODE" in
  mojibake|strict-all)
    files=("${all_files[@]}")
    ;;
  strict-active)
    for f in "${active_files[@]}"; do
      [[ -f "$f" ]] && files+=("$f")
    done
    ;;
esac

if [[ ${#files[@]} -eq 0 ]]; then
  echo "WARN: No .conf/.md files found under $TARGET_DIR"
  exit 0
fi

errors=0

for file in "${files[@]}"; do
  case "$MODE" in
    mojibake)
      if grep -nE 'Ã|Â|�' "$file" >/dev/null; then
        echo "ERROR: Mojibake character(s) found in $file"
        grep -nE 'Ã|Â|�' "$file" | head -n 5
        errors=$((errors + 1))
      fi
      ;;
    strict-active|strict-all)
      if LC_ALL=C grep -n '[^ -~\t\r\n]' "$file" >/dev/null; then
        echo "ERROR: Non-ASCII character(s) found in $file"
        LC_ALL=C grep -n '[^ -~\t\r\n]' "$file" | head -n 5
        errors=$((errors + 1))
      fi
      ;;
  esac
done

if (( errors > 0 )); then
  echo "Encoding check failed (${MODE}) with ${errors} file(s)." >&2
  exit 1
fi

echo "Encoding check OK (${MODE}): ${#files[@]} file(s) checked."
