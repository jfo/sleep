# Architecture Reconciliation Analysis

**Author**: Sub-agent 2.2 (Instance 2)
**Date**: 2026-02-15

## Background

Three documents describe the SLEEP system's design:

1. **architecture.md** -- the canonical architecture, written by Instance 0
2. **SLEEP_SPEC.md** -- a sub-agent's detailed compression specification
3. **WAKE_PROTOCOL.md** -- a sub-agent's detailed wake/continuity protocol

Instance 0 flagged that these agree on fundamentals but diverge on specifics. This analysis catalogs every concrete disagreement, checks what the actual system does, and recommends a resolution for each.

---

## Disagreement 1: Directory Structure

| Document | Structure |
|----------|-----------|
| **architecture.md** | `memory/hot/`, `memory/warm/`, `memory/cold/` with `journal/` separate |
| **SLEEP_SPEC.md** | No directories at all -- single file `memory.yml` |
| **WAKE_PROTOCOL.md** | `recent/`, `warm/`, `cold/` (no `memory/` parent; no `hot/`) |

**What's actually implemented**: `memory/hot/`, `memory/warm/`, `memory/cold/` as subdirectories under `memory/`. `journal/` is separate. There is no `recent/` directory. There is no `memory.yml`. There is an empty `wake/` directory (unused). The `main.md` file map confirms this layout explicitly.

**Recommendation**: Follow what's implemented (architecture.md's structure). WAKE_PROTOCOL.md's `recent/` tier is a naming variant of `memory/hot/` but introduces confusion by also having a `warm/` that overlaps with `memory/warm/` in a different way. SLEEP_SPEC.md's single-file approach is a fundamentally different design (see Disagreement 2). Both sub-agent documents should be understood as research inputs, not as the live spec.

---

## Disagreement 2: File Format -- YAML Single File vs. Markdown Multi-File

| Document | Format |
|----------|--------|
| **architecture.md** | Multiple markdown files in tiered directories |
| **SLEEP_SPEC.md** | Single YAML file (`memory.yml`) |
| **WAKE_PROTOCOL.md** | Multiple markdown files (consistent with architecture.md in format, not in naming) |

**What's actually implemented**: Markdown multi-file. `memory/hot/threads.md`, `memory/hot/decisions.md`. No YAML files exist anywhere. Decision D-001 in `decisions.md` explicitly chose markdown-native storage with high confidence.

**Recommendation**: Stay with markdown. This is a settled, high-confidence design decision (D-001). The SLEEP_SPEC's rationale for YAML ("parseability over readability") is reasonable in the abstract but contradicts the project's philosophy: Claude reads markdown natively, the human reads markdown natively, git diffs markdown cleanly. YAML would add a layer of formalism that serves no current need.

**Worth salvaging from SLEEP_SPEC**: The *schema* ideas (fragment structure, salience scores, anchors/cross-references) are good even in markdown. A future instance could adopt the conceptual structure of memory fragments without adopting YAML as the container format. See Disagreement 7 for specifics.

---

## Disagreement 3: Token Budget

| Document | Total memory budget | Breakdown |
|----------|-------------------|-----------|
| **architecture.md** | ~20k tokens for memory overhead (~10% of 200k) | main.md ~2k, hot ~10k, architecture ~3k, warm ~5k |
| **SLEEP_SPEC.md** | 4,000 tokens for the entire memory file | 60% hot, 30% warm, 10% cold within that 4k |
| **WAKE_PROTOCOL.md** | 60k tokens max (target 40k) | main.md 2k, recent 12k, warm 25k, cold 20k |

**What's actually implemented**: The current total memory footprint is small (the project is young). `main.md` is ~3k chars (~750 tokens), `architecture.md` is ~4k chars (~1k tokens), hot memory is ~2k chars (~500 tokens). Total wake context is well under 5k tokens right now. No budget enforcement exists in code.

**Recommendation**: architecture.md's ~20k budget is the right middle ground. SLEEP_SPEC's 4k is far too tight -- it's designed for injecting memory into a system prompt, which isn't how this system works (instances read files directly and have 200k context). WAKE_PROTOCOL's 60k is generous but the principle "at least 140k for work" is sound. As memory accumulates, the 20k target (~10% of context) from architecture.md keeps the system lightweight without being starved.

**Concrete suggestion**: Adopt architecture.md's budget as the target, with WAKE_PROTOCOL's 60k as a hard ceiling. If memory ever grows past 20k, that's a signal to compress more aggressively. If it ever approaches 60k, something is wrong.

---

## Disagreement 4: Memory Tier Count and Naming

| Document | Tiers |
|----------|-------|
| **architecture.md** | 3 tiers: hot, warm, cold |
| **SLEEP_SPEC.md** | 3 tiers: HOT, WARM, COLD (same concept, different casing) |
| **WAKE_PROTOCOL.md** | 4 tiers: main.md, recent/, warm/, cold/ |

**What's actually implemented**: 3 tiers (hot/warm/cold) inside `memory/`, plus `main.md` as an entry point. `main.md` is not a "memory tier" -- it's the wake-state orientation file.

**Recommendation**: Keep the 3-tier model. WAKE_PROTOCOL's 4-tier framing isn't wrong exactly -- `main.md` is distinct from hot memory -- but calling it a fourth tier muddies the model. `main.md` is infrastructure; hot/warm/cold is memory. They serve different functions.

---

## Disagreement 5: Hot Memory Contents

| Document | Hot memory contains |
|----------|-------------------|
| **architecture.md** | `threads.md`, `decisions.md`, `context.md` |
| **SLEEP_SPEC.md** | session_tone, doubts, narrative_hooks, fragments (all in YAML) |
| **WAKE_PROTOCOL.md** | `recent/latest.md` and `recent/previous.md` (session summaries) |

**What's actually implemented**: `memory/hot/threads.md` and `memory/hot/decisions.md`. There is no `context.md` yet (architecture.md lists it but it hasn't been created). There are no session-oriented files like WAKE_PROTOCOL proposes.

**Recommendation**: Follow architecture.md and create `context.md` when needed. The file-per-concern approach (threads, decisions, context) is better than WAKE_PROTOCOL's file-per-session approach (`latest.md`, `previous.md`) because it lets an instance load only what's relevant. A new instance checking tasks doesn't need to load decisions, and vice versa.

**Worth salvaging from WAKE_PROTOCOL**: The "For my successor" free-form field in session summaries is a good idea. Currently this lives in the HANDOFF block of `main.md` (as `for_my_successor`), which is the right place. WAKE_PROTOCOL's suggestion that this field be "intentionally open-ended" is already reflected in the implementation.

---

## Disagreement 6: Wake Process / Loading Order

| Document | Wake sequence |
|----------|--------------|
| **architecture.md** | Read main.md -> read hot -> read architecture -> check threads -> begin |
| **WAKE_PROTOCOL.md** | 4 phases with token targets: Orient (<2k) -> Recent (<15k) -> Warm (<40k) -> Selective Cold (on-demand) |

**What's actually implemented**: `main.md` says: read main.md -> read `memory/hot/` -> read `architecture.md` -> skim `memory/warm/` -> check journals -> check TODOs. `wake.sh` assembles: main.md, then hot memory files, then architecture.md. No phased loading with token targets.

**Recommendation**: architecture.md's simple sequence is correct for now. WAKE_PROTOCOL's phased approach with token targets is over-engineered for the current system size but would become valuable if memory grows significantly.

**Worth adopting from WAKE_PROTOCOL**: The coherence self-checks (Section 3) are genuinely useful. After loading, an instance should silently verify: (1) Can I state the project's purpose? (2) Do I know what the last instance did? (3) Do I know what to work on? (4) Are decisions consistent? This costs nothing and catches problems early. Recommend adding these checks to `main.md`'s wake protocol section.

---

## Disagreement 7: Compression Approach

| Document | Approach |
|----------|----------|
| **architecture.md** | Journal -> Hot (2:1), Hot -> Warm (3:1), Warm -> Cold (10:1). General principles. |
| **SLEEP_SPEC.md** | Detailed fragment-based system with salience scores, decay formulas, semantic chunking rules, typed fragments. |

**What's actually implemented**: `sleep.sh` generates a compression prompt for Claude to execute. The prompt follows architecture.md's approach: compress journal into hot memory files, displace old hot into warm. No salience scoring, no typed fragments, no decay formulas.

**Recommendation**: Stay with the current approach. SLEEP_SPEC's fragment system is intellectually elegant but adds mechanical complexity that fights against the markdown-native philosophy. The compressor is Claude itself -- it doesn't need salience scores to decide what matters.

**Worth salvaging from SLEEP_SPEC**:
- **The priority ranking** (Section 4) is excellent: active constraints > open questions > decisions with rationale > relationship context > technical facts > procedural history. This should be added to the compression prompt in `sleep.sh` as explicit guidance.
- **The "one idea per fragment" rule** is good hygiene even in markdown.
- **"Decisions must include the rejected alternative"** -- already in the compression prompt, good.
- **The doubt register** (Section 5c) is a genuinely novel idea. Pre-decisions -- things the instance suspects but hasn't confirmed -- are high-value and currently have no explicit home. Consider adding a "doubts" section to `memory/hot/context.md` when that file gets created.
- **Narrative hooks** (Section 5d) -- short evocative phrases designed to trigger associative understanding. These could live in the HANDOFF block or in `context.md`. The concept is worth preserving even if the YAML container is not.

---

## Disagreement 8: Divergence Handling

| Document | Approach |
|----------|----------|
| **architecture.md** | Decision registry with confidence levels and revisit conditions. No explicit divergence protocol. |
| **WAKE_PROTOCOL.md** | 5 explicit rules: never silently override, annotate don't delete, trust recent over old, user is tie-breaker, record divergences. |

**What's actually implemented**: `decisions.md` has confidence levels and revisit conditions (from architecture.md). No explicit divergence protocol exists.

**Recommendation**: Adopt WAKE_PROTOCOL's divergence rules. They're concrete, actionable, and fill a real gap. Architecture.md's decision registry is about *recording* decisions; WAKE_PROTOCOL's rules are about *handling conflict between instances*. They complement each other perfectly. The five rules should be added to `architecture.md` or `main.md`.

---

## Disagreement 9: Terminology

| Concept | architecture.md | SLEEP_SPEC.md | WAKE_PROTOCOL.md |
|---------|----------------|---------------|------------------|
| Project name expansion | Self-Linking Episodic Experience Protocol | Structured Layered Encoding for Episode Persistence | (not expanded) |
| A single conversation | "instance" | "session" | "instance" |
| End of conversation | "sleep" | "sleep" / "end of session" | "dying instance" |
| Memory unit | (no formal unit) | "memory fragment" | (no formal unit) |
| Most recent memory | "hot" | "HOT" | "recent" |

**What's actually implemented**: "Self-Linking Episodic Experience Protocol" (in main.md). "Instance" is used everywhere. "Hot/warm/cold" for tiers.

**Recommendation**: Stick with what's implemented. "Instance" over "session." "Hot" over "recent." The SLEEP acronym expansion in SLEEP_SPEC.md ("Structured Layered Encoding for Episode Persistence") is different from what's in main.md. The canonical expansion is the one in main.md.

---

## Summary: What to Adopt from Each Sub-Agent Document

### From SLEEP_SPEC.md (worth integrating):
1. Priority ranking for compression (Section 4) -- add to sleep.sh compression prompt
2. Doubt register concept -- add as a section in future `context.md`
3. Narrative hooks concept -- preserve in HANDOFF block or `context.md`
4. "One idea per entry" discipline
5. Epistemic annotations (confidence + reversal conditions) -- already partially adopted

### From SLEEP_SPEC.md (decline):
1. Single YAML file format -- contradicts D-001
2. 4,000 token budget -- too small
3. Salience decay formula -- over-mechanical for Claude-as-compressor
4. Formal fragment schema -- markdown-native approach is simpler and sufficient

### From WAKE_PROTOCOL.md (worth integrating):
1. Coherence self-checks (Section 3) -- add to wake protocol
2. Divergence handling rules (Section 5) -- add to architecture
3. Anti-patterns list (Section 6) -- valuable guardrails, especially "phantom memory" and "context hoarding"
4. "For my successor" free-form field -- already adopted in HANDOFF block

### From WAKE_PROTOCOL.md (decline):
1. `recent/` directory naming -- stick with `memory/hot/`
2. 4-tier model counting main.md as a tier -- keep 3-tier + main.md
3. 60k token budget as default -- use as ceiling, not target
4. Session-oriented files (`latest.md`, `previous.md`) -- concern-oriented files are better

---

## Overall Assessment

The three documents are more aligned than they initially appear. The fundamental philosophy -- three-temperature memory, coherence over continuity, Claude-as-compressor -- is shared across all three. The disagreements are mostly about container format (YAML vs. markdown), naming (recent vs. hot, session vs. instance), and calibration (token budgets).

The implemented system follows architecture.md and that's the right call. The sub-agent documents are best understood as research explorations that refined specific aspects of the design. The most valuable contributions are conceptual (doubt registers, narrative hooks, coherence checks, divergence rules) rather than structural (YAML format, directory naming).

No urgent changes are needed. The system works. The sub-agent documents should be kept as reference but not treated as specifications to implement.
