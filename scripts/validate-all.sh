#!/bin/bash
# ==============================================================================
# Validate All Environments
# ==============================================================================
# Runs terraform validate on every environment to catch config errors.
#
# Usage: ./scripts/validate-all.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
ENVS_DIR="${PROJECT_ROOT}/environments"

PASSED=0
FAILED=0
ERRORS=""

echo "=============================================="
echo "  Validating All Terraform Environments"
echo "=============================================="
echo ""

for ENV_DIR in "${ENVS_DIR}"/*/; do
  ENV_NAME=$(basename "${ENV_DIR}")
  echo "🔍 Validating: ${ENV_NAME}..."

  cd "${ENV_DIR}"

  # Init without backend (no AWS credentials needed for validation)
  if terraform init -backend=false -no-color > /dev/null 2>&1; then
    if terraform validate -no-color > /dev/null 2>&1; then
      echo "   ✅ ${ENV_NAME}: PASSED"
      PASSED=$((PASSED + 1))
    else
      echo "   ❌ ${ENV_NAME}: FAILED (validate)"
      ERRORS="${ERRORS}\n  - ${ENV_NAME}: $(terraform validate -no-color 2>&1)"
      FAILED=$((FAILED + 1))
    fi
  else
    echo "   ❌ ${ENV_NAME}: FAILED (init)"
    ERRORS="${ERRORS}\n  - ${ENV_NAME}: init failed"
    FAILED=$((FAILED + 1))
  fi

  cd "${PROJECT_ROOT}"
done

echo ""
echo "=============================================="
echo "  Results: ${PASSED} passed, ${FAILED} failed"
echo "=============================================="

if [ ${FAILED} -gt 0 ]; then
  echo ""
  echo "Errors:"
  echo -e "${ERRORS}"
  exit 1
fi

echo ""
echo "✅ All environments validated successfully!"
