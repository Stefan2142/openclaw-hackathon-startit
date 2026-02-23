#!/bin/bash
# ============================================================
# Run All Pin-Tests Sequentially
# ============================================================
# Tests each pipeline agent in isolation with pinned input.
# Use before demos to verify the entire pipeline works.
#
# Usage:
#   bash test-all.sh          # Run all 5 agents
#   bash test-all.sh quick    # Run only Claims Officer + Finance (fastest)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "  OpenClaw Pipeline Pin-Test Suite"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

if [ "$1" = "quick" ]; then
  echo "QUICK MODE: Testing Claims Officer and Finance only"
  echo ""
  bash "$SCRIPT_DIR/test-claims-officer.sh"
  echo ""
  echo "--------------------------------------------"
  echo ""
  bash "$SCRIPT_DIR/test-finance.sh"
else
  AGENTS=("claims-officer" "assessor" "fraud-analyst" "senior-reviewer" "finance")
  SCRIPTS=("test-claims-officer.sh" "test-assessor.sh" "test-fraud-analyst.sh" "test-senior-reviewer.sh" "test-finance.sh")

  for i in "${!AGENTS[@]}"; do
    echo ""
    echo "============================================"
    echo "  Testing: ${AGENTS[$i]} ($((i + 1))/${#AGENTS[@]})"
    echo "============================================"
    echo ""
    bash "$SCRIPT_DIR/${SCRIPTS[$i]}"
    echo ""
    echo "--------------------------------------------"

    # Brief pause between agents to avoid gateway overload
    if [ $i -lt $((${#AGENTS[@]} - 1)) ]; then
      echo "Pausing 5s before next agent..."
      sleep 5
    fi
  done
fi

echo ""
echo "============================================"
echo "  All tests complete!"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
