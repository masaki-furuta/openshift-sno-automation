#!/bin/bash
set -euo pipefail

# =======================
# Configuration
# =======================
ROOT_DIR="openshift-sno-automation"
CURRENT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT_DIR="$CURRENT_DIR/$ROOT_DIR"
OLD_DIR="$CURRENT_DIR/old-scripts"

DRYRUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRYRUN=true
  echo "🧪 Dry-run mode enabled. No files will be modified."
fi

# =======================
# Select base script or create new one
# =======================
echo "🔍 Available scripts:"
mapfile -t SCRIPT_CANDIDATES < <(
  find "$SCRIPT_DIR/contrib" "$SCRIPT_DIR/devel" -type f -name "*.sh"
  find "$CURRENT_DIR" -maxdepth 1 -type f -name "create-openshift-sno-structure.sh"
)

select SCRIPT_PATH in "${SCRIPT_CANDIDATES[@]}" "[Other: Create new script]"; do
  if [[ -n "$SCRIPT_PATH" && "$SCRIPT_PATH" != "[Other: Create new script]" ]]; then
    break
  elif [[ "$SCRIPT_PATH" == "[Other: Create new script]" ]]; then
    read -rp "📎 Enter new script name (without .sh): " NEW_SCRIPT_NAME
    [[ -z "$NEW_SCRIPT_NAME" ]] && echo "❌ Script name cannot be empty" && exit 1
    SCRIPT_PATH="$SCRIPT_DIR/contrib/${NEW_SCRIPT_NAME}.sh"
    echo "# New script: $NEW_SCRIPT_NAME" > "$SCRIPT_PATH"
    echo "✅ Created new script at: $SCRIPT_PATH"
    break
  fi
  echo "⚠ Invalid selection. Try again."
done

BASENAME=$(basename "$SCRIPT_PATH")
BASENAME_NOEXT="${BASENAME%.sh}"
LATEST=$(find "$OLD_DIR" -type f -name "${BASENAME_NOEXT}_v*.sh" 2>/dev/null | \
  sed -E "s#.*/${BASENAME_NOEXT}_v([0-9]+)\\.sh#\1#;t;d" | sort -n | tail -n1 || echo 0)
NEXT=$((LATEST + 1))
VERSION="v${NEXT}"
TEMP_EDIT_FILE="/tmp/${BASENAME_NOEXT}_edit_$$.sh"
OLD_VERSION_FILE="$OLD_DIR/${BASENAME_NOEXT}_${VERSION}.sh"

if $DRYRUN; then
  echo "[dry-run] Would duplicate $SCRIPT_PATH → $TEMP_EDIT_FILE"
else
  cp "$SCRIPT_PATH" "$TEMP_EDIT_FILE"
fi

if $DRYRUN; then
  echo "[dry-run] Would open editor: vim $TEMP_EDIT_FILE"
else
  vim "$TEMP_EDIT_FILE"
fi

if $DRYRUN; then
  echo "[dry-run] Would compare original and edited using diff"
  echo "[dry-run] Would save backup to: $OLD_VERSION_FILE"
  echo "[dry-run] Would overwrite: $SCRIPT_PATH with edited content"
  echo "[dry-run] Would remove temporary file: $TEMP_EDIT_FILE"
else
  echo "🧾 Diff between original and edited:"
  if ! diff -q "$SCRIPT_PATH" "$TEMP_EDIT_FILE" >/dev/null; then
    icdiff "$SCRIPT_PATH" "$TEMP_EDIT_FILE" || true
    read -rp "✅ Save changes and version this edit ($VERSION)? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      cp "$SCRIPT_PATH" "$OLD_VERSION_FILE"
      cp "$TEMP_EDIT_FILE" "$SCRIPT_PATH"
      echo "✅ Changes saved. Versioned as $VERSION."
    else
      echo "❌ Changes discarded."
    fi
  else
    echo "⚠ No differences detected. Nothing to do."
  fi
  rm -f "$TEMP_EDIT_FILE"
fi

