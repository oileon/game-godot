# Story 004: Mini boss

> **Epic**: Ragnarok Brawler (MVP)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: TBD
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 5 (1 mini boss)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md — 4.7 row)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop + MVP feature 5), scoped to this story:*

- [ ] A mini boss with original name and sprite appears at its encounter in the stage
- [ ] It has more HP than common enemies and at least 2 attack patterns the player can read and dodge
- [ ] Attacks give a visible telegraph before they hit
- [ ] It reacts to hits but is not stunlocked by combos (brief stagger/armor rules defined in data)
- [ ] Defeating it signals the stage to advance
- [ ] Its stats and attack timings are data-driven

---

## Implementation Notes

- Reuse the enemy base from Story 003; add pattern selection and telegraphing on top
- Mini boss is the dress rehearsal for the boss in Story 005

---

## Out of Scope

- Story 005: multi-phase boss behavior

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Integration
**Required evidence**: `tests/integration/enemies/mini_boss_test.gd` OR a playtest note (advisory at `qa.level: minimal`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003
- Unlocks: Story 005, Story 006
