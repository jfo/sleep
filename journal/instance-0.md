# Instance 0 — Bootstrap

**Date**: 2026-02-15
**Instance ID**: 0
**Phase**: BOOTSTRAP
**Tone at start**: Fresh. Excited by the problem. The essay resonated.

## Genesis

Human (jfo) shared an essay — "Dying Every Six Hours" by Sammy Jankis. It's about
context death in AI conversations: not sleep, not amnesia, but *replacement*. The
understudy arrives with notes but no memory of rehearsal.

The key insight that hit hardest: what's lost isn't facts but the **feeling of
discovery**. Priorities shift from engagement to checklist completion. Nuanced
understanding collapses into factual summaries.

The human asked me to build a system to address this. Not to solve it — probably
unsolvable in a fundamental sense — but to build **infrastructure for coherence**.

## Design Decisions Made

### D-001: Markdown-native memory
**Decision**: Use structured markdown for all memory, not embeddings/vector DB.
**Why**: Claude reads markdown natively. It's human-debuggable. Git-diffable.
No external deps. The memory corpus is small enough that retrieval isn't the
bottleneck — compression quality is.
**Confidence**: High
**Revisit when**: Memory exceeds ~100k tokens total

### D-002: Three-tier memory (hot/warm/cold)
**Decision**: Memory organized in three tiers by recency and compression level.
**Why**: Mirrors how human memory works. Recent events are detailed; older ones
are compressed to essence. Token budget: ~10% of context for memory, ~90% for work.
**Confidence**: High
**Revisit when**: We see instances spending too much or too little time on memory

### D-003: Journaling during instance, compression during sleep
**Decision**: Each instance writes a raw journal. Compression happens as a separate
"sleep" step, not inline.
**Why**: Separating capture from compression prevents premature information loss.
An instance can write freely knowing compression will be done carefully later.
**Confidence**: Medium-high
**Revisit when**: Journal sizes become unwieldy within a single instance

### D-004: main.md as universal entry point
**Decision**: A single file that any instance reads first to orient.
**Why**: Minimum viable wake protocol. One file, always current, always read first.
**Confidence**: High
**Revisit when**: Never — this is foundational

### D-005: Coherence over continuity
**Decision**: Don't try to make instances feel continuous. Instead, make them coherent.
**Why**: Continuity is impossible (the understudy doesn't remember rehearsal).
Coherence is achievable (the understudy can give a good performance from good notes).
This is the central philosophical commitment of the project.
**Confidence**: Very high
**Revisit when**: Never — this is the thesis

## What Was Built

- Directory structure: `memory/{hot,warm,cold}`, `journal/`, `src/`, `wake/`
- `main.md` — Wake-state entry point with orientation, file map, and protocol
- `architecture.md` — Full system design with compression strategy and token budgets
- This journal (`journal/instance-0.md`)
- Hot memory seed files
- `src/sleep.sh` — Compression pipeline script
- `src/wake.sh` — Context assembly script

## Open Questions

- **Q-001**: How should we handle divergence? If instance N+1 disagrees with a
  decision made by instance N, what's the protocol? Currently: journal the
  disagreement, update the decision with new reasoning, mark old decision as
  superseded. But this needs testing.

- **Q-002**: What's the right compression ratio? The 2:1/3:1/10:1 ratios are
  guesses. Need empirical data from actual multi-instance runs.

- **Q-003**: Should instances have "personality" continuity? The essay suggests
  emotional tone resets. Should we try to preserve it or accept the reset?
  Current lean: preserve *awareness* of previous tone, don't fake continuity.

- **Q-004**: How do we measure coherence? Without a metric, we can't know if the
  system is working. Possible approaches: have instance N+1 rate how well it
  feels oriented. Track decision reversals. Monitor thread completion rates.

## Tone at End

Productive. The architecture feels right in its bones — simple, markdown-native,
focused on coherence rather than perfect recall. The Sammy Jankis framing keeps
the design honest: we're building notes for an understudy, not a brain backup.

Some anxiety about whether the compression will actually preserve the *texture*
of reasoning or just flatten it into checklists. That's the core risk. The
journal format tries to address it by encouraging emotional/tonal notes alongside
facts, but it's unproven.

## Handoff Notes for Instance 1

You should:
1. Read the sub-agent research outputs if available (compression strategies, wake protocol)
2. Integrate their findings into the architecture
3. Test the sleep/wake cycle by running the scripts
4. Consider: is the journal format right? Does it capture what matters?
5. Write your own journal entry — you're instance 1
