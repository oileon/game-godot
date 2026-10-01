# Story 003: Common enemies and horde AI

> **Epic**: Ragnarok Brawler (MVP)
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: TBD
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-01

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

- [x] 3–5 enemy types exist, each with a distinct behavior (e.g. melee rusher, ranged, tank), original names and sprites — 3 types: Cinderling (fast/fragile rusher), Slagbrute (slow/tanky, armored mid-attack), Ashspitter (ranged, keeps distance, fires a projectile). Original names, placeholder art with distinct silhouettes (screenshot 01)
- [x] Enemies spawn in groups and approach, attack, and take damage from the player — OBSERVED: 4 enemies spawn from data, states IDLE/APPROACH/WAIT_RING/ATTACK all reached in a 10–15s sim; player's attacks damage them (verified via direct kill + via a real multi-hit test below)
- [x] Enemies react to hits: flinch, knockback, stun, and die at 0 HP — HURT state + KnockbackMotion + hitstun scaled by stats; DEAD at 0 HP; Slagbrute's `armor_during_attack` takes damage without flinching mid-swing (documented design choice)
- [x] A group of enemies does not all attack at once — attackers are staggered so the player can read threats — OBSERVED: max simultaneous token holders and max simultaneous ATTACK-phase enemies both held at ≤2 (matching `max_attackers=2`) continuously over 10–15s of simulated real time, confirmed twice (before and after the review fixes); screenshot 02 shows the debug HUD reading "Attack tokens: [Cinderling]" (one holder) while others wait
- [x] The player's combos (Story 002) hit multiple enemies and control the group — OBSERVED: one real `attack_basic` input with two enemies in range produced exactly 2 `hit_landed` signals (the existing multi-target hitbox resolution, unmodified, already handles enemies)
- [x] A group counts as cleared when all its enemies are dead, which the stage can listen to — OBSERVED: killing all 4 enemies fired `enemy_died` exactly 4 times and `group_cleared` exactly once; `get_alive_count()==0`/`is_cleared()==true` held after corpses faded and freed themselves, confirmed both before and after the review fixes
- [x] Enemy stats and behavior parameters are data-driven — all tunables in `EnemyStats`/`ProjectileData` `.tres` files; confirmed by `godot-gdscript-specialist` review (2 small hardcoded values found and moved to data, see Implementation Notes)

---

## Implementation Notes

- Keep enemy AI as simple state machines (idle, approach, attack, hurt, dead); one shared base, per-type data
- Emit a signal when a group is cleared so Story 006 can advance the stage

**Design (2026-10-01):** One `Enemy` (CharacterBody2D) driven entirely by `EnemyStats` data; a pure-logic `AttackTokenPool` (RefCounted FIFO, max N simultaneous holders) and `RingLayout` (static ring-slot math) keep the horde staggered without autoloads — everything injected via `configure()`. `EncounterGroup` (Node2D, not an autoload) spawns from `EncounterData`, tracks alive/dead counts, and emits `group_cleared` exactly once. A new `enemy_arena.tscn` hosts the fight; `test_arena.tscn` (Stories 001/002) is untouched.

**Post-implementation note (orchestrator + godot-gdscript-specialist review, 2026-10-01):**
- `godot-gdscript-specialist` verdict: **APPROVE WITH NOTES**, no blocking issues. Three should-fix items, all applied and reverified:
  1. Two hardcoded gameplay values moved to data: `enemy.gd`'s facing-direction deadzone (4.0px) → `EnemyStats.facing_deadzone`; the retreat "close enough" multiplier (×0.5 on `arrive_tolerance`) → `EnemyStats.retreat_settle_fraction`. Both defaults match prior behavior exactly, so no `.tres` file needed updating.
  2. `RingLayout.compute()`'s mirror-then-clamp can silently collapse multiple ring slots onto the same level edge if the ring distance exceeds the room on *both* sides of the player (a narrow arena or a much larger roster) — **not reachable with this story's shipped data** (max distance ~480px vs. a 2800px level), but documented in-code as a known limitation and given a partial mitigation (slots that hit this case now separate along the depth lane instead of fully overlapping). Flagged explicitly for Story 004/005, whose boss arenas may be narrower.
- Remaining nice-to-haves (not applied, not blocking): `state_changed`/`attack_phase_changed` signals currently have no listener (the placeholder visual polls getters instead — fine, just noting so it isn't later read as dead code); `AttackTokenPool.max_tokens` has no write-time validation; a `set_deferred`/direct-set asymmetry between `_begin_attack`'s `hitbox.monitoring = true` and `_end_attack`'s `set_deferred`; the shared single `RandomNumberGenerator` instance across sibling enemies in a group (deterministic today via fixed tree order, but worth a comment for future maintainers).
- Two of the orchestrator's own verification attempts were initially misleading due to its own test-script bugs, not implementation bugs: a GDScript lambda capturing an `int` local by value (documented gotcha in this project's own `current-best-practices.md`) made a `group_cleared`/`enemy_died` counter read 0 when the real count was correct; and an "walk into an enemy" collision test showed a much larger gap than expected because the target enemy's own AI was simultaneously repositioning it — not a collision failure. Both redone correctly (mutable-array counter; an inert, un-targeted enemy for the pure physics check).

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

**Status**: [x] Created — `production/qa/evidence/story-003-enemies-horde-ai/01-group-spawned.png`, `02-staggered-attack-and-wait.png`. Unit test waived (advisory) at `qa.level: minimal` — not written.

---

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: Story 004, Story 006

---

## Completion Notes
**Completed**: 2026-10-01
**Criteria**: 7/7 passing, none deferred. Feel (stagger pacing, enemy variety) confirmed by the owner playing the build ("ficou bom").
**Deviations**: None against the brief.
**Test Evidence**: Logic — unit test waived (advisory) at `qa.level: minimal`, not written. Screenshots in `production/qa/evidence/story-003-enemies-horde-ai/`.
**Code Review**: `godot-gdscript-specialist` reviewed (APPROVE WITH NOTES) — 3 should-fix items applied and reverified (facing_deadzone/retreat_settle_fraction moved to EnemyStats; RingLayout mirror-collapse documented + mitigated). `LP-CODE-REVIEW` skipped (solo mode).
**Carried forward (not tracked in the debt register)**: `state_changed`/`attack_phase_changed` signals have no listener yet (placeholder visual polls instead); `AttackTokenPool.max_tokens` has no write-time validation; `set_deferred`/direct-set asymmetry in `_begin_attack`/`_end_attack`; shared single RNG instance across sibling enemies (deterministic today, worth a comment); RingLayout's ring-collapse limitation should be re-checked before Story 004/005 if their arenas are narrower than this one's 2800px.
