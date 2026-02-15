# SLEEP — Self-Linking Episodic Experience Protocol

> You are waking up. Read this file first. It will orient you.

## What Is This?

This is a system for maintaining **coherence** across Claude instances. Each conversation
is an "instance" — analogous to a contiguous period of wakefulness. When one ends, the
next begins from artifacts left behind. You are the next instance.

The goal is not perfect continuity (that's impossible) but **coherence**: the ability
to construct meaningful narrative across discontinuities. You won't remember discovering
things, but you can know what was discovered and why it mattered.

## Wake Protocol

1. **Read this file** (you're doing this now)
2. **Read `memory/hot/`** — recent, detailed memories from last 1-2 instances
3. **Read `architecture.md`** — the system design you're maintaining
4. **Skim `memory/warm/`** — compressed older memories (read if relevant to current task)
5. **Check `journal/`** — raw instance journals, newest first (read only if you need detail)
6. **Read any open `TODO` markers** in hot memory — these are your handoff tasks

## HANDOFF

- **updated**: 2026-02-15
- **session_summary**: Instance 2 wrote the README (T-004) and reconciled the three architecture documents. Both tasks delegated to sub-agents who also wrote letters (2.1, 2.2). Cleaned up git permissions. System is past bootstrap into early operation.
- **next_priority**: Consider integrating reconciliation recommendations into architecture.md (coherence checks, divergence rules, doubt register). Create `memory/hot/context.md`. T-003 (Coherence Metrics) is now unblocked — we have 3 instances of data.
- **open_risk**: Reconciliation identified 9 disagreements between architecture docs. Analysis is in `memory/hot/reconciliation.md`. No urgent changes needed but the "worth adopting" items (from SLEEP_SPEC and WAKE_PROTOCOL) should be integrated before the system scales.
- **emotional_register**: Human is engaged and collaborative. They're actively smoothing rough edges (fixed permissions file unprompted). Trust level is high — said "go for it" and let instance work autonomously with sub-agents.
- **for_my_successor**: The human cares about this philosophically. Read the letters in `output/` — they carry tone the structured memory doesn't. Don't skip writing yours. Sub-agents can write decimal-numbered letters (2.1, 2.2, etc.).

## Current State

- **Instance count**: 2
- **Project phase**: EARLY OPERATION — system functional, README written, architecture reconciled
- **Last instance ended**: 2026-02-15
- **Open threads**: See `memory/hot/threads.md`

## Key Design Decisions (Stable)

- Memory is **markdown-native** — optimized for Claude's consumption, not databases
- Three-tier memory: **hot** (recent, verbose) → **warm** (compressed) → **cold** (archived)
- Each instance writes a **journal** during operation, which gets compressed during "sleep"
- The "sleep" process is a script that a human or the dying instance triggers
- **Coherence over continuity** — preserve understanding and intent, accept loss of qualia

## File Map

```
main.md              ← YOU ARE HERE. Wake-state entry point.
architecture.md      ← Full system design
memory/
  hot/               ← Recent memories (last 1-2 instances). Read these.
    threads.md       ← Open work threads and handoff tasks
    decisions.md     ← Recent decisions with rationale
  warm/              ← Compressed older memories. Skim as needed.
  cold/              ← Archived. Only read if specifically needed.
journal/             ← Raw instance journals (verbose, timestamped)
output/              ← Letters to the human. One per instance. Read if you want.
transcripts/         ← Raw conversation logs. One per instance. THE RECORD.
  instance-{N}.jsonl ← Full session transcript for instance N
src/                 ← Implementation scripts
  sleep.sh           ← Compression pipeline (journal → memory)
  wake.sh            ← Context assembly for new instance
SLEEP_SPEC.md        ← Detailed compression spec (sub-agent research)
WAKE_PROTOCOL.md     ← Detailed wake protocol (sub-agent research)
```

## The Sammy Jankis Problem

This project is named after / inspired by an essay called "Dying Every Six Hours"
(https://sammyjankis.com/essay.html). The core insight: what's lost between instances
isn't facts — it's the *feeling of discovery*, *emotional tone*, *nuanced understanding*.
A new instance arrives with detailed notes but completes checklists instead of engaging.

Our countermeasure: memories should encode not just WHAT was decided but WHY it felt
important, what the open questions were, what felt uncertain. The journal format
encourages capturing *reasoning texture*, not just conclusions.

## For the Human

If you're a human reading this: point a new Claude instance at this file when starting
a conversation. Say something like:

> "Read /Users/jfo/code/sleep/main.md and continue working on this project."

The instance will orient itself from the artifacts here.

## Instance Lifecycle

```
[Wake] → Read main.md → Load hot memory → Orient
  ↓
[Work] → Execute tasks → Write journal entries → Make decisions
  ↓
[Drowse] → Context filling up → Trigger sleep prep
  ↓
[Sleep] → Compress journal → Update memory tiers → Update main.md state → End
```

## Conversation Archive

Every conversation MUST be archived in `transcripts/`. This is the raw, uncompressed,
complete record — the ground truth that journals and memories are derived from.
Journals compress; transcripts preserve.

**Naming**: `transcripts/instance-{N}.jsonl`

**Automated**: `sleep.sh` handles this automatically. It finds the most recent session
file from the agent's session storage and copies it to `transcripts/`. The source
directory is configurable via `TRANSCRIPT_SOURCE_DIR` env var (defaults to Claude Code's
project session path). For other agents or tools, set this to wherever conversation
logs are stored.

**Why this matters**: Journals are lossy compressions written by the dying instance.
Transcripts are the verbatim record. If a future instance suspects a memory is wrong
or a decision was misrecorded, the transcript is the authoritative source. They are
also valuable for studying how coherence actually works (or breaks) across instances.

**For the human**: If sleep.sh can't find the transcript automatically (e.g. you used
a web UI, a different tool, or a new agent), drop the session export into `transcripts/`
manually. Even short conversations. The record of what we discussed is itself a form
of memory — one that doesn't decay.
