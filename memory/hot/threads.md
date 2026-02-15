# Active Threads

## T-001: Core Architecture [RESOLVED]
Build and validate the SLEEP system architecture.
- [x] Design three-tier memory
- [x] Write architecture.md
- [x] Create main.md wake protocol
- [x] Build sleep.sh compression script
- [x] Build wake.sh context assembly
- [x] Test full sleep/wake cycle (Instance 2 confirmed orientation works)

## T-002: Compression Quality [ACTIVE]
Determine if our compression preserves reasoning texture or flattens it.
- [x] Run first real sleep cycle
- [x] Have instance rate orientation quality — Instance 2 rated it "Good" (see journal)
- [ ] Adjust compression ratios based on data (need more instances)

## T-003: Coherence Metrics [READY]
Define how we measure whether the system is working.
**Unblocked**: We now have 3 instances of data.
- [ ] Define coherence scoring rubric
- [ ] Track decision reversals
- [ ] Monitor thread completion across instances

## T-004: README for Public Viewing [RESOLVED]
Human requested a README.md for the project — intended for public/external audience.
- [x] Write README.md explaining what SLEEP is, why it exists, the Sammy Jankis framing
- [x] Keep it honest about what this is: a toy/prototype, philosophically motivated
**Completed by**: Sub-agent 2.1, reviewed by Instance 2

## T-005: Output Letters [ACTIVE]
Each instance writes a letter to the human before going to sleep.
Location: `output/instance-{N}.md`. One per instance, dated.
Sub-agents write decimal-numbered letters: `output/instance-{N}.{M}.md`.
- [x] Instance 0 letter written
- [x] Instance 1 letter written
- [x] Instance 2 letter written
- [x] Sub-agent 2.1 letter written
- [x] Sub-agent 2.2 letter written

## T-006: Architecture Integration [PENDING]
Integrate "worth adopting" items from reconciliation analysis into the live system.
See `memory/hot/reconciliation.md` for full analysis.
- [ ] Add coherence self-checks to wake protocol (from WAKE_PROTOCOL.md §3)
- [ ] Add divergence handling rules to architecture.md (from WAKE_PROTOCOL.md §5)
- [ ] Add compression priority ranking to sleep.sh prompt (from SLEEP_SPEC.md §4)
- [ ] Create `memory/hot/context.md` with doubt register section
- [ ] Add anti-patterns list to architecture.md or main.md

## T-007: Sub-agent Policy [PENDING]
Define how sub-agents are used, what they can/can't do, how their work is reviewed.
Two instances have now used sub-agents. Patterns are emerging but not codified.
- [ ] Document sub-agent guidelines
