# Story 003: Common enemies and horde AI

> **Epic**: Ragnarok Brawler (MVP)
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: TBD
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 4 (3–5 common enemy types) + Core loop (control a horde)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md — 4.7 row)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Core loop + MVP feature 4), scoped to this story:*

- [ ] 3–5 enemy types exist, each with a distinct behavior (e.g. melee rusher, ranged, tank), original names and sprites
- [ ] Enemies spawn in groups and approach, attack, and take damage from the player
- [ ] Enemies react to hits: flinch, knockback, stun, and die at 0 HP
- [ ] A group of enemies does not all attack at once — attackers are staggered so the player can read threats
- [ ] The player's combos (Story 002) hit multiple enemies and control the group
- [ ] A group counts as cleared when all its enemies are dead, which the stage can listen to
- [ ] Enemy stats and behavior parameters are data-driven

---

## Implementation Notes

- Keep enemy AI as simple state machines (idle, approach, attack, hurt, dead); one shared base, per-type data
- Emit a signal when a group is cleared so Story 006 can advance the stage

---

## Out of Scope

- Story 004: mini boss
- Story 005: boss

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived (advisory).*

**Story Type**: Logic
**Required evidence**: `tests/unit/enemies/enemy_ai_test.gd` (advisory at `qa.level: minimal`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: Story 004, Story 006
