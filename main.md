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

## Current State

- **Instance count**: 0 (you are instance 1 if reading this for the first time after bootstrap)
- **Project phase**: BOOTSTRAP — initial architecture and toy implementation
- **Last instance ended**: 2026-02-15 (bootstrap)
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
src/                 ← Implementation scripts
  sleep.sh           ← Compression pipeline (journal → memory)
  wake.sh            ← Context assembly for new instance
wake/                ← Wake protocol artifacts and templates
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
