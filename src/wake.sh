#!/usr/bin/env bash
#
# wake.sh — Assemble context for a new Claude instance.
#
# Usage: ./src/wake.sh
#
# Outputs the full wake context that should be fed to a new instance.
# This is the "alarm clock" — it gathers everything the instance needs
# to orient itself and begin work.
#

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== WAKE CONTEXT ==="
echo ""
echo "Point a new Claude instance to this project and say:"
echo ""
echo '  "Read /path/to/sleep/main.md and follow the wake protocol."'
echo ""
echo "=== CONTEXT ASSEMBLY ==="
echo ""

# Phase 1: Orient
echo "--- PHASE 1: ORIENT (main.md) ---"
echo ""
if [ -f "$PROJECT_ROOT/main.md" ]; then
    cat "$PROJECT_ROOT/main.md"
else
    echo "[WARNING] main.md not found. Cold start."
fi
echo ""

# Phase 2: Hot memory
echo "--- PHASE 2: HOT MEMORY ---"
echo ""
for f in "$PROJECT_ROOT/memory/hot/"*.md; do
    if [ -f "$f" ]; then
        echo "=== $(basename "$f") ==="
        cat "$f"
        echo ""
    fi
done

# Phase 3: Architecture (for reference)
echo "--- PHASE 3: ARCHITECTURE ---"
echo ""
if [ -f "$PROJECT_ROOT/architecture.md" ]; then
    cat "$PROJECT_ROOT/architecture.md"
fi
echo ""

# Token estimate
TOTAL_CHARS=0
for f in "$PROJECT_ROOT/main.md" "$PROJECT_ROOT/architecture.md"; do
    if [ -f "$f" ]; then
        TOTAL_CHARS=$((TOTAL_CHARS + $(wc -c < "$f")))
    fi
done
for f in "$PROJECT_ROOT/memory/hot/"*.md; do
    if [ -f "$f" ]; then
        TOTAL_CHARS=$((TOTAL_CHARS + $(wc -c < "$f")))
    fi
done

# Rough estimate: ~4 chars per token
EST_TOKENS=$((TOTAL_CHARS / 4))

echo "=== TOKEN ESTIMATE ==="
echo "Wake context: ~${EST_TOKENS} tokens"
echo "Remaining for work: ~$((200000 - EST_TOKENS)) tokens"
echo "======================"
