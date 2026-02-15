#!/usr/bin/env bash
#
# sleep.sh — Compress an instance's journal into memory and archive the transcript.
#
# Usage: ./src/sleep.sh [instance_number]
#
# This script:
# 1. Archives the raw conversation transcript (the ground truth)
# 2. Assembles a compression prompt for the agent to process
# 3. The agent compresses journal → hot memory, old hot → warm
# 4. Updates main.md with the handoff block
# 5. Commits the result
#
# Transcript source is configurable via TRANSCRIPT_SOURCE_DIR.
# Default: Claude Code's project session dir.
# Set to any directory containing session files (most recent = current).
#

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTANCE="${1:-}"

# --- Transcript source configuration ---
# Claude Code stores sessions as .jsonl in this path.
# Override TRANSCRIPT_SOURCE_DIR for other agents/tools.
ESCAPED_PATH=$(echo "$PROJECT_ROOT" | sed 's|/|-|g')
TRANSCRIPT_SOURCE_DIR="${TRANSCRIPT_SOURCE_DIR:-$HOME/.claude/projects/${ESCAPED_PATH}}"

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

# --- Archive transcript ---
TRANSCRIPT_DIR="$PROJECT_ROOT/transcripts"
TRANSCRIPT_DEST="$TRANSCRIPT_DIR/instance-${INSTANCE}.jsonl"
mkdir -p "$TRANSCRIPT_DIR"

if [ -f "$TRANSCRIPT_DEST" ]; then
    echo "Transcript: already archived at $TRANSCRIPT_DEST"
elif [ -d "$TRANSCRIPT_SOURCE_DIR" ]; then
    # Find the most recently modified session file
    LATEST_SESSION=$(ls -t "$TRANSCRIPT_SOURCE_DIR"/*.jsonl 2>/dev/null | head -1)
    if [ -n "$LATEST_SESSION" ]; then
        cp "$LATEST_SESSION" "$TRANSCRIPT_DEST"
        echo "Transcript: archived $(basename "$LATEST_SESSION") → transcripts/instance-${INSTANCE}.jsonl"
    else
        echo "Transcript: WARNING — no session files found in $TRANSCRIPT_SOURCE_DIR"
    fi
else
    echo "Transcript: WARNING — source dir not found: $TRANSCRIPT_SOURCE_DIR"
    echo "           Set TRANSCRIPT_SOURCE_DIR to your agent's session storage path."
fi
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
