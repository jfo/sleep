#!/usr/bin/env bash
#
# sleep.sh — Compress an instance's journal into memory.
#
# Usage: ./src/sleep.sh [instance_number]
#
# This script assembles a compression prompt and feeds it to Claude,
# which performs the actual compression. Claude IS the compressor.
#
# What it does:
# 1. Reads the current instance's journal
# 2. Reads current hot memory
# 3. Asks Claude to compress journal → new hot, old hot → warm
# 4. Updates main.md with the handoff block
# 5. Commits the result
#

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTANCE="${1:-}"

if [ -z "$INSTANCE" ]; then
    # Auto-detect: find the highest instance number in journal/
    INSTANCE=$(ls "$PROJECT_ROOT/journal/" 2>/dev/null \
        | grep -o 'instance-[0-9]*' \
        | sed 's/instance-//' \
        | sort -n \
        | tail -1)
    if [ -z "$INSTANCE" ]; then
        echo "Error: No journals found and no instance number provided."
        exit 1
    fi
fi

JOURNAL="$PROJECT_ROOT/journal/instance-${INSTANCE}.md"

if [ ! -f "$JOURNAL" ]; then
    echo "Error: Journal not found: $JOURNAL"
    exit 1
fi

echo "=== SLEEP PROCESS ==="
echo "Instance: $INSTANCE"
echo "Journal:  $JOURNAL"
echo ""

# Assemble the compression prompt
PROMPT=$(cat <<'PROMPT_EOF'
You are the SLEEP compressor for the SLEEP system. Your job is to compress
an instance's journal into structured memory.

Read the journal and current memory state provided below. Then:

1. Write NEW hot memory files:
   - memory/hot/threads.md — Update thread statuses based on journal
   - memory/hot/decisions.md — Add any new decisions from the journal
   - memory/hot/context.md — Current state summary for next instance

2. If there's existing hot memory that's being displaced, compress it
   into warm memory files organized by topic in memory/warm/.

3. Update main.md:
   - Increment the instance count
   - Update "Last instance ended" date
   - Write the HANDOFF section with:
     - session_summary (1-2 sentences)
     - next_priority (single most important next action)
     - open_risk (anything fragile or risky)
     - emotional_register (tone of the work)

COMPRESSION RULES:
- Preserve WHY decisions were made, not just WHAT
- Preserve open questions — they don't decay
- Preserve emotional/tonal notes — "this felt wrong" is data
- Compress procedural details aggressively (drop steps, keep conclusions)
- Reference code by git commit, don't copy verbatim
- One idea per memory entry
- Decisions MUST include rejected alternatives

Read all the files in the project first, then perform the compression
by editing the files directly. Commit the result with message:
"sleep: compress instance N journal into memory"
PROMPT_EOF
)

echo "Launching Claude compressor..."
echo ""

# Feed Claude the compression task
# The human runs this and Claude does the actual work
echo "--- COMPRESSION PROMPT ---"
echo ""
echo "$PROMPT"
echo ""
echo "--- JOURNAL CONTENT ---"
echo ""
cat "$JOURNAL"
echo ""
echo "--- CURRENT HOT MEMORY ---"
echo ""
for f in "$PROJECT_ROOT/memory/hot/"*.md; do
    if [ -f "$f" ]; then
        echo "=== $(basename "$f") ==="
        cat "$f"
        echo ""
    fi
done
echo "=========================="
echo ""
echo "To run this compression, start a new Claude instance and paste the above,"
echo "or run: claude --print \"$(echo "$PROMPT" | head -5)...\" with the full context."
echo ""
echo "Alternatively, point a Claude instance at this project and say:"
echo "  'Read main.md, then run the sleep process for instance $INSTANCE'"
