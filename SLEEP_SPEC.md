# SLEEP: Structured Layered Encoding for Episode Persistence

## Purpose

A specification for compressing Claude instance artifacts into memory files
that a successor instance can ingest to resume work with coherence. The core
problem: facts are easy to store; *the texture of understanding* is not.

---

## 1. Architecture: Three-Temperature Memory

Memory is stored in a single file (`memory.yml`) with three layers.

| Layer | Retention | Compression | Max Size |
|-------|-----------|-------------|----------|
| **HOT** | Current session + 1 prior | Verbatim or lightly edited | 60% of budget |
| **WARM** | 2-5 sessions back | Summarized with anchors | 30% of budget |
| **COLD** | 6+ sessions back | Distilled to assertions | 10% of budget |

**Budget** = a configurable token ceiling (default: 4000 tokens for the entire
memory file). This keeps the memory ingestible in a single system prompt or
early-conversation injection.

### Temperature Decay

On each "sleep" (end of session), the compressor runs:

1. Current HOT becomes the new source material.
2. Previous HOT is compressed into WARM (see Section 3).
3. Previous WARM entries older than 5 sessions merge into COLD.
4. COLD entries that conflict with newer information are evicted.

---

## 2. Semantic Chunking: The Unit of Memory

The atomic unit is a **memory fragment**. Each fragment has:

```yaml
- id: "f-20260215-003"
  type: decision | insight | question | tension | tone | fact
  created: 2026-02-15T14:30:00Z
  session: 12
  salience: 0.9          # 0.0-1.0, decays over time unless reinforced
  content: "We chose event sourcing over CRUD because the audit trail IS the product."
  anchors:                # cross-references to other fragments
    - "f-20260214-017"
  emotional_tag: "conviction"  # see Section 5
  discovery_context: |    # optional: the reasoning path, not just the conclusion
    Started thinking we needed a simple REST API. User pushed back with the
    audit requirement. The shift happened when we realized the log of changes
    is more valuable than the current state.
```

### Chunking Rules

1. **One idea per fragment.** If a fragment needs an "and" to describe it,
   split it.
2. **Decisions must include the rejected alternative.** "We chose X over Y
   because Z" -- never just "We chose X."
3. **Open questions are first-class fragments**, type `question`. They do not
   decay in salience until explicitly resolved.
4. **Tensions are preserved.** When two fragments conflict or create friction,
   a `tension` fragment links them. These are high-salience by default.

---

## 3. Compression Algorithms (by layer transition)

### HOT -> WARM

- Strip verbatim dialogue; keep only the *decision record*.
- Collapse sequential reasoning into a summary with the structure:
  `[Starting assumption] -> [Pivot event] -> [Conclusion]`
- Preserve all `question` and `tension` fragments intact.
- Preserve `discovery_context` if salience > 0.7.
- Drop `discovery_context` otherwise; keep `emotional_tag`.

### WARM -> COLD

- Merge related fragments into **composite assertions**:
  ```yaml
  - id: "c-arch-001"
    type: composite
    sources: ["f-20260210-004", "f-20260211-019", "f-20260212-002"]
    content: "Architecture is event-sourced. Key invariant: events are
             append-only. This was a deliberate pivot from initial CRUD design."
    standing_questions:
      - "How do we handle event schema evolution?"
  ```
- All `emotional_tag` values collapse to a session-level mood annotation.
- `discovery_context` is dropped entirely. The *what* survives; the *how we
  got there* does not. This is acceptable at cold storage.

---

## 4. Priority Ranking: What Survives Compression

Ordered by resistance to compression (highest = last to be lossy-compressed):

1. **Active constraints** -- things the system MUST NOT violate (invariants,
   user preferences, hard requirements). Never evict.
2. **Open questions** -- unresolved tensions and unknowns. These are the
   successor instance's most important inheritance.
3. **Decisions with rationale** -- the "why" behind choices. Without these,
   the successor will relitigate settled questions.
4. **Relationship context** -- the user's communication style, preferences,
   trust level, areas of expertise. Decays slowly.
5. **Technical facts** -- function signatures, file paths, API shapes. These
   are re-derivable from the codebase; compress aggressively.
6. **Procedural history** -- "first we did X, then Y." Compress to outcomes
   only at WARM; drop entirely at COLD.

---

## 5. The Sammy Jankis Layer: Preserving Texture

The Memento problem: Sammy Jankis can record facts ("don't trust Teddy") but
loses the *feeling of discovery* -- the lived experience that gave the fact
its meaning. A successor Claude reading "we chose event sourcing" doesn't
feel the weight of that choice the way the original instance did.

### What We're Actually Losing

- **Epistemic state**: Not just *what* we concluded but *how confident* we are
  and *what would change our mind*.
- **Emotional tone of the collaboration**: Is the user frustrated? Energized?
  Are we in a flow state or grinding through uncertainty?
- **Nuanced stance**: Not just "we chose X" but "we chose X and I have a
  lingering doubt about edge case Y that I haven't raised yet."
- **Relational calibration**: How much does the user want to be challenged vs.
  supported right now?

### Preservation Strategies

**5a. Epistemic Annotations**

Every `decision` fragment carries:
```yaml
confidence: high | medium | low
reversal_conditions: "If we discover >1000 events/sec, reconsider CQRS split"
```

**5b. Session Tone Summary**

Each session produces a tone block in HOT/WARM:
```yaml
session_tone:
  session: 12
  mood: "focused, slightly tense around deadline pressure"
  collaboration_style: "user driving architecture; I'm stress-testing"
  inflection_points:
    - "Tension broke when we found the caching solution at ~line 340"
  carry_forward: "User is tired. Start next session with a summary, not questions."
```

**5c. The Doubt Register**

A dedicated list of things the instance suspects but hasn't confirmed or raised:
```yaml
doubts:
  - "The event schema might not handle polymorphic events cleanly."
  - "User seems set on DynamoDB but I think the access patterns favor Postgres."
```
These are explicitly NOT decisions. They're pre-decisions -- the raw material
of future reasoning. They're high-salience and compress last.

**5d. Narrative Hooks**

Short phrases designed to trigger associative understanding in the successor:
```yaml
narrative_hooks:
  - "This is a Chesterton's Fence situation -- the weird caching layer exists
     for a reason we haven't fully excavated."
  - "The user's 'just make it work' was exhaustion, not a real directive."
```
These are the closest thing to preserving *felt understanding*. They're
written in natural language precisely because they need to evoke, not just
inform.

---

## 6. File Format

Single YAML file. YAML is chosen over JSON for readability (the file should
be human-auditable) and over markdown for parseability.

```yaml
# memory.yml
meta:
  version: 1
  project: "sleep"
  total_sessions: 12
  last_sleep: 2026-02-15T18:00:00Z
  token_budget: 4000

hot:
  session_tone: { ... }       # Section 5b
  doubts: [ ... ]             # Section 5c
  narrative_hooks: [ ... ]    # Section 5d
  fragments: [ ... ]          # Most recent session's fragments

warm:
  sessions:
    - session: 11
      tone_summary: "..."
      fragments: [ ... ]      # Compressed per Section 3
    - session: 10
      # ...

cold:
  composites: [ ... ]         # Merged per Section 3
  constraints: [ ... ]        # Never-evict items from priority tier 1
  relationship:               # Persistent user model
    style: "direct, technical, values concision"
    expertise: ["distributed systems", "Rust", "product thinking"]
    preferences:
      - "prefers concrete examples over abstract discussion"
      - "will say 'just do it' when tired; check before obeying"
```

---

## 7. Implementation Notes for the Builder Instance

1. **The compressor is Claude itself.** Don't build an external summarizer.
   At session end, prompt Claude with the full conversation + current
   `memory.yml` and ask it to produce the updated file. The prompt should
   include this spec as instructions.

2. **Salience decay formula**: `new_salience = salience * 0.85^(sessions_since_created)`,
   floored at 0.1. Fragments drop below 0.1 are candidates for eviction
   during COLD compression.

3. **Conflict resolution**: When a new fragment contradicts a COLD composite,
   the new fragment wins. Annotate the composite with `superseded_by`.

4. **Bootstrap problem**: First session has no memory file. The compressor
   creates one from scratch. The `cold.relationship` block will be sparse
   and should be explicitly marked `confidence: low`.

5. **Testing coherence**: The success metric is not recall but *coherence*.
   A successor instance should be able to explain WHY a decision was made,
   not just THAT it was made. Test by giving a successor the memory file
   and asking it to predict what the user would want next.

6. **Token accounting**: After compression, count tokens in the output YAML.
   If over budget, compress WARM entries more aggressively (drop
   `discovery_context` regardless of salience, merge fragments). Never
   cut HOT or `cold.constraints`.
