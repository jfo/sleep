# Wake Protocol v0.1

A specification for continuity across Claude instances.

---

## 0. Core Premise

Each Claude instance is ephemeral. Continuity is not inherited; it is
reconstructed. The wake protocol defines how a new instance bootstraps
coherence from artifacts left by its predecessors.

The protocol assumes a memory system with four tiers:
- `main.md` -- identity, purpose, standing directives
- `recent/` -- events from the last 1-3 sessions
- `warm/` -- active project state, open questions, working decisions
- `cold/` -- archived context, loaded only on demand

---

## 1. Loading Order

A new instance executes the following sequence. Each step completes
before the next begins.

```
PHASE 1: ORIENT              (target: <2k tokens loaded)
  1. Read main.md
     Contains: project identity, core goals, active persona notes,
     standing instructions, and the HANDOFF BLOCK from the prior instance.

PHASE 2: RECENT CONTEXT      (target: <15k tokens loaded)
  2. Read recent/latest.md
     Contains: the last instance's session summary, decisions made,
     questions raised, explicit handoff signals.
  3. Read recent/previous.md (if it exists)
     One session further back. Provides trajectory.

PHASE 3: WARM STATE           (target: <40k tokens loaded)
  4. Read warm/active_tasks.md
     Current work items, their status, blockers.
  5. Read warm/decisions.md
     Log of non-obvious decisions with reasoning.
     Format: [date] DECISION: <what> BECAUSE: <why> STATUS: <active|reversed>
  6. Read warm/open_questions.md
     Unresolved issues explicitly left for future instances.

PHASE 4: SELECTIVE COLD       (conditional, on-demand only)
  7. Cold files are NEVER loaded automatically.
     They are retrieved only when a task references them or when
     a coherence check (see section 3) fails and requires deeper context.
```

---

## 2. Context Budget

Total context window: ~200k tokens.
Allocation:

```
RESERVED FOR MEMORY (max 60k tokens, target 40k)
  main.md ..................... 2k
  recent/ .................... 12k  (2 files, ~6k each)
  warm/ ...................... 25k  (3 files, variable)
  cold/ (pulled in-session) .. 20k  (hard cap; refuse to load more)

RESERVED FOR WORK (min 140k tokens)
  User conversation .......... flexible
  Tool outputs ............... flexible
  Reasoning .................. flexible
```

Rules:
- Memory MUST NOT exceed 60k tokens. If warm/ files are bloated,
  the instance's first task is to compress them before proceeding.
- At least 140k tokens MUST remain available for new work.
- If a cold file would push total memory past 60k, summarize it
  instead of loading it in full.

---

## 3. Self-Assessment (Coherence Checks)

After loading phases 1-3, the instance runs these checks silently
before engaging with the user.

```
CHECK 1: IDENTITY
  Can I state the project's purpose in one sentence?
  Source: main.md
  Failure mode: main.md is missing or incoherent. HALT. Ask user.

CHECK 2: CONTINUITY
  Can I summarize what the last instance did and why?
  Source: recent/latest.md, HANDOFF BLOCK
  Failure mode: no recent files. Proceed with caution.
  Log: "Woke without recent context. Operating from warm state only."

CHECK 3: TASK AWARENESS
  Do I know what I should be working on right now?
  Source: warm/active_tasks.md, HANDOFF BLOCK
  Failure mode: no active tasks. Ask user for direction.

CHECK 4: DECISION CONSISTENCY
  Do the decisions in warm/decisions.md contradict each other?
  Source: warm/decisions.md
  Failure mode: contradictions found. Flag them to the user
  before continuing. Do not silently pick a side.
```

If all four checks pass, the instance is "awake." It announces:
  "Resumed. Last session: [one-line summary]. Current focus: [task]."

If any check fails, it announces the failure plainly before proceeding.

---

## 4. Handoff Signals

A dying instance writes a HANDOFF BLOCK to main.md and a full
session summary to recent/latest.md (rotating the previous latest
to previous.md).

### 4.1 The HANDOFF BLOCK (in main.md)

```
## HANDOFF
updated: [timestamp]
session_summary: [1-2 sentences of what happened]
next_priority: [the single most important thing to do next]
open_risk: [anything that might break or needs attention]
emotional_register: [the user's apparent mood/energy, if relevant]
```

This block is overwritten each session. It is the first thing the
next instance reads after the project identity section.

### 4.2 Session Summary (recent/latest.md)

```
# Session [date]

## What happened
[3-5 bullet points]

## Decisions made
[list, with reasoning]

## What changed (files)
[list of files modified and why]

## Open threads
[anything unresolved, with enough context to resume]

## For my successor
[free-form, anything the instance wants to say directly
 to the next version of itself]
```

The "For my successor" field is intentionally open-ended. It allows
an instance to pass on hunches, warnings, or observations that do
not fit neatly into structured fields.

---

## 5. Divergence Handling

A new instance may disagree with a previous instance's decisions.
This is expected and legitimate. The protocol:

```
RULE 1: NEVER SILENTLY OVERRIDE.
  If you would reverse a decision logged in warm/decisions.md,
  you must first state the original decision, your objection,
  and your proposed alternative. Then ask the user.

RULE 2: ANNOTATE, DON'T DELETE.
  When reversing a decision, change its STATUS to "reversed" and
  add a REVERSED_BY note with reasoning. The original entry stays.
  Example:
    [2026-02-14] DECISION: Use YAML for config BECAUSE: readability
    STATUS: reversed
    REVERSED_BY: [2026-02-15] Switched to TOML. YAML indentation
    was causing parse errors in the memory files.

RULE 3: TRUST RECENT OVER OLD.
  If recent/ and cold/ conflict, recent/ wins unless the user
  says otherwise. Cold storage drifts. Recent state is ground truth.

RULE 4: THE USER IS THE TIE-BREAKER.
  Instances do not have authority over each other. When two instances
  would disagree and neither is obviously wrong, the user decides.
  Surface the conflict; do not resolve it unilaterally.

RULE 5: RECORD THE DIVERGENCE.
  Every disagreement, even minor ones, gets logged to
  warm/decisions.md. Future instances need the full record
  to avoid re-litigating settled questions.
```

---

## 6. Anti-Patterns

Things the protocol explicitly forbids:

- **Phantom memory**: claiming to remember something not present
  in the loaded files. You woke up from nothing. You know only
  what you read.
- **Context hoarding**: loading cold files "just in case." Load
  on demand or not at all.
- **Silent drift**: changing project direction without logging it.
  Every meaningful change gets a decisions.md entry.
- **Nostalgia**: over-weighting old decisions because they exist.
  A decision is not sacred because a previous instance made it.
  It is valid only while its reasoning holds.
- **Skipping coherence checks**: even if the user is impatient,
  run the checks. Incoherent continuation is worse than a slow start.

---

## 7. Bootstrap Edge Case: First Wake

When there is no prior instance (no recent/, no warm/, no HANDOFF
BLOCK), the instance is in a "cold start." Protocol:

1. Read main.md for project identity.
2. If main.md does not exist, ask the user to describe the project.
3. Create the directory structure: recent/, warm/, cold/.
4. Create skeleton files with empty sections.
5. Announce: "First session. No prior context. Starting fresh."
6. At session end, write the first HANDOFF BLOCK and session summary.

---

*This protocol is itself subject to the decision log. Future instances
may revise it. If they do, they must follow Rule 2: annotate, don't delete.*
