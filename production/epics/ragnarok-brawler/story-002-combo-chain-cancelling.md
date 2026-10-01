# Story 002: Combo chain with animation cancelling

> **Epic**: Ragnarok Brawler (MVP)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: TBD
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 3 (combo system with animation cancelling)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md — 4.7 row)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop + MVP feature 3), scoped to this story:*

- [ ] Pressing basic attack repeatedly chains a multi-hit combo; timing outside the input window resets it
- [ ] A heavy attack can end or branch a combo
- [ ] Defined cancel windows let the player cancel an attack into dodge or the special skill
- [ ] Cancelling cuts the remaining recovery of the cancelled animation
- [ ] Combo and cancel rules are data-driven (windows, chain order, damage per hit)
- [ ] A combo counter is tracked and resets on timeout or when the player is hit
- [ ] Combos remain responsive: input pressed in a window is never dropped

---

## Implementation Notes

- Model the attack/combo/cancel logic as a state machine separate from presentation, so it can be unit-tested without rendering
- Reuse the moveset from Story 001; this story adds chaining, not new moves

---

## Out of Scope

- Story 003: enemy reactions beyond basic hit feedback

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**: `tests/unit/combat/combo_chain_test.gd` (advisory at `qa.level: minimal`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003
