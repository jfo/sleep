# SLEEP Architecture

## Overview

SLEEP (Self-Linking Episodic Experience Protocol) maintains coherence across Claude
instances through a cycle of journaling, compression, and structured wake-up.

## Core Concepts

### Instance
A single Claude conversation. Finite context window (~200k tokens). Analogous to a
contiguous period of wakefulness. Has a unique incrementing ID.

### Journal
Raw, verbose capture of an instance's work. Written *during* the instance. Contains:
- Decisions made and their reasoning
- Code written or modified
- Open questions and uncertainties
- Emotional/tonal notes (what felt important, what was surprising)
- Handoff notes for the next instance

Format: `journal/instance-{N}.md`

### Memory Tiers

**Hot** (`memory/hot/`) — Last 1-2 instances. Detailed. Always loaded on wake.
- `threads.md` — Active work threads, open tasks, blockers
- `decisions.md` — Recent decisions with full rationale
- `context.md` — Current project state, what's being worked on

**Warm** (`memory/warm/`) — Older memories, compressed ~3:1 from hot.
- Organized by topic, not by instance
- Loaded selectively based on current task relevance
- Format: `warm/{topic}.md`

**Cold** (`memory/cold/`) — Archived. Compressed ~10:1 from warm.
- Key decisions and outcomes only
- Loaded only when specifically referenced
- Format: `cold/{topic}.md`

### Sleep Process
Triggered when an instance is ending. Steps:
1. Instance writes final journal entries (handoff notes)
2. `sleep.sh` runs (can be triggered by instance or human)
3. Current hot memory → compressed into warm
4. Journal → compressed into new hot memory
5. `main.md` state section updated
6. Changes committed

### Wake Process
A new instance begins:
1. Human points instance to `main.md`
2. Instance reads hot memory
3. Instance reads architecture (this file)
4. Instance checks threads.md for open work
5. Instance begins journaling as new instance N+1

## Compression Strategy

### What to Preserve (High Priority)
- **Reasoning chains**: WHY decisions were made, not just what
- **Open questions**: Uncertainty is more valuable than false certainty
- **Emotional markers**: "This felt wrong," "this was surprising" — these encode
  intuitions that don't reduce to facts
- **Architectural decisions**: These compound — losing one can cascade
- **Relationship between pieces**: How components connect, not just what they are

### What to Compress Aggressively (Low Priority)
- Verbatim code (it's in git, reference by commit)
- Step-by-step debugging traces (keep conclusion, drop steps)
- Exploratory dead ends (keep "tried X, didn't work because Y", drop details)
- Boilerplate decisions (standard patterns don't need rationale)

### Compression Ratios
- Journal → Hot: ~2:1 (drop verbosity, keep substance)
- Hot → Warm: ~3:1 (merge related decisions, drop per-instance framing)
- Warm → Cold: ~10:1 (key outcomes and stable decisions only)

## Coherence Mechanisms

### Narrative Threading
Each work thread gets an ID and tracks across instances. Threads are:
- **active**: Being worked on
- **paused**: Set aside intentionally (with reason)
- **resolved**: Completed (with outcome)
- **abandoned**: Dropped (with reason)

### Decision Registry
Significant decisions are registered with:
- What was decided
- Why (reasoning)
- What alternatives were considered
- Confidence level (high/medium/low)
- Revisit conditions (when should this be reconsidered?)

### Tone Preservation
Each instance's journal starts with a "tone check" — read the previous instance's
closing tone and acknowledge it. Not to fake continuity, but to maintain awareness
of the emotional trajectory of the work.

## Token Budget (per instance ~200k)

| Allocation     | Tokens  | Purpose                              |
|---------------|---------|--------------------------------------|
| main.md       | ~2k     | Orientation                          |
| Hot memory    | ~10k    | Recent context                       |
| Architecture  | ~3k     | System design (this file)            |
| Warm memory   | ~5k     | Selectively loaded older context     |
| **Available** | **~180k** | **New work within the instance**   |

Total memory overhead: ~10% of context. This is intentional — most of the window
should be available for actual work. Memory is a scaffold, not a cage.

## Implementation Notes

### Why Markdown?
- Claude reads markdown natively and efficiently
- Human-readable for debugging
- Git-diffable for history
- No external dependencies (no vector DB, no embeddings service)
- Structured enough for parsing, flexible enough for nuance

### Why Not Embeddings?
For the toy implementation: unnecessary complexity. Embeddings shine for retrieval
over large corpora. Our memory store is small enough (~20k tokens warm + cold) that
full-text works fine. If the memory grows past ~100k tokens, we should revisit.

### Future Directions
- Embedding-based retrieval for cold storage at scale
- Cross-project memory (sharing insights between different codebases)
- Instance "personality" tracking (how does tone/style drift across instances?)
- Automated coherence scoring (does instance N+1 feel like a continuation of N?)
