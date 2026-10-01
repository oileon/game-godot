# Story 005: Boss with phases

> **Epic**: Ragnarok Brawler (MVP)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: TBD
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 6 (1 boss with at least 2 phases)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md — 4.7 row)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Player goal & fail state + MVP feature 6), scoped to this story:*

- [ ] A boss with original name and sprite appears in its own arena
- [ ] It has at least 2 phases with a clear transition (e.g. at an HP threshold)
- [ ] Each phase has different attack patterns, all telegraphed
- [ ] The phase change is visible and audible to the player
- [ ] Phase thresholds, HP, and attack parameters are data-driven
- [ ] Defeating the boss emits a "boss defeated" signal that the stage uses to end the fight
- [ ] The boss does not soft-lock: if the player dies, the encounter can reset cleanly

---

## Implementation Notes

- Build on the mini boss (Story 004): same telegraph and pattern machinery, plus a phase state machine
- Keep phase transitions driven by data so tuning does not need code changes

---

## Out of Scope

- Story 006: stage flow and victory screen

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**: `tests/integration/enemies/boss_phases_test.gd` OR a playtest note (advisory at `qa.level: minimal`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 004
- Unlocks: Story 006
