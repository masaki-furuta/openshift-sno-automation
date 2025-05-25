#!/bin/bash
set -euo pipefail

# =======================
# Execution Directory Check (Project Root Verification)
# =======================
# Determine the directory where this script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The project root is one level up from the script directory
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Verify that the expected project structure exists
if [[ ! -d "$PROJECT_ROOT/contrib" ]] || [[ ! -d "$PROJECT_ROOT/devel" ]] || [[ ! -d "$PROJECT_ROOT/old-scripts" ]]; then
  echo "❌ Error: Please run this script in the project root directory as checked out via git clone."
  exit 1
fi

# Use the project root as the working directory
CURRENT_DIR="$PROJECT_ROOT"

find $CURRENT_DIR -name '*yaml' -exec yamllint {} \; 

