# Recent Decisions

## D-001: Markdown-native memory
Use structured markdown for all memory storage.
**Rationale**: Native to Claude, human-debuggable, git-diffable, no external deps.
**Alternatives rejected**: Vector DB (overkill for small corpus), JSON (less readable),
SQLite (adds dependency, not Claude-native).
**Confidence**: High | **Revisit**: Memory > 100k tokens

## D-002: Three-tier memory (hot/warm/cold)
Hot (recent, detailed) → Warm (older, 3:1 compressed) → Cold (archived, 10:1).
**Rationale**: Mirrors human memory. Keeps token budget at ~10% of context.
**Confidence**: High | **Revisit**: Instances under/over-spending on memory load

## D-003: Separate capture and compression
Journal during instance; compress during sleep.
**Rationale**: Prevents premature information loss.
**Confidence**: Medium-high | **Revisit**: Journals too large for single instance

## D-004: main.md universal entry point
Single file, always read first by any new instance.
**Confidence**: High | **Revisit**: Never

## D-005: Coherence over continuity
Don't fake continuity. Build coherent narrative from discontinuous instances.
**Rationale**: Continuity is impossible. Coherence is achievable and honest.
**Confidence**: Very high | **Revisit**: Never — this is the thesis
