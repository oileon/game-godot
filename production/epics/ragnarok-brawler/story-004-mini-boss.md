# Story 004: Mini boss

> **Epic**: Ragnarok Brawler (MVP)
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: TBD
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-01

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

- [x] A mini boss with original name and sprite appears at its encounter in the stage — "Ashwarden", original name, distinct crimson/horned placeholder silhouette (screenshot 01)
- [x] It has more HP than common enemies and at least 2 attack patterns the player can read and dodge — 500 HP (vs. 30–160 for common enemies); Quick Slash (fast, short-range) and Ruin Slam (slow, wide, long-range) — OBSERVED alternating strictly across 6 consecutive attacks in a scripted run, never repeating back-to-back
- [x] Attacks give a visible telegraph before they hit — OBSERVED: screenshots 02/03 show visually distinct telegraphs (Ruin Slam's wide ground zone + warning circle vs. Quick Slash's smaller contained box), not just different numbers
- [x] It reacts to hits but is not stunlocked by combos (brief stagger/armor rules defined in data) — OBSERVED: a hit during its own ATTACK state deals damage (500→470) without interrupting the swing (`armor_during_attack`); a hit outside ATTACK causes a brief HURT (reduced `hitstun_scale`/`knockback_scale`), confirmed short and non-looping
- [x] Defeating it signals the stage to advance — OBSERVED: `died` and `boss_defeated` both fired exactly once when HP reached 0
- [x] Its stats and attack timings are data-driven — all in `mini_boss.tres`/attack `.tres` files; no hardcoded gameplay numbers in the new `.gd` files (confirmed by reading the code)

---

## Implementation Notes

- Reuse the enemy base from Story 003; add pattern selection and telegraphing on top
- Mini boss is the dress rehearsal for the boss in Story 005

**Design (2026-10-01):** Solo 1v1 fight — deliberately does NOT use Story 003's `AttackTokenPool`/`RingLayout` (those stagger a horde; irrelevant for one boss). `MiniBoss extends Enemy`, `BossStats extends EnemyStats` (inherits HP/speed/hitstun_scale/knockback_scale/armor_during_attack for free) adding `attack_patterns: Array[AttackData]` + weighted-exclude-last-used selection. **No Story 003 file was touched** — `enemy.gd`/`enemy_stats.gd`/`enemy.tscn`/`encounter_group.gd`/`attack_token_pool.gd`/`ring_layout.gd` all confirmed unmodified (`git diff --stat` empty) and independently re-parse-checked alongside the new files. New standalone `boss_arena.tscn`, does not touch `enemy_arena.tscn`.

**Post-implementation note (orchestrator + godot-gdscript-specialist review, 2026-10-01):**
- Orchestrator independently verified: parse check (10/10 ok, including re-checking all untouched Story 003 files); 500 HP; strict pattern alternation over 6 attacks; armor-during-attack (hit lands, no flinch, 500→470); reduced-but-nonzero hitstun outside ATTACK; `died`/`boss_defeated` both firing exactly once on death; two visually distinct telegraphs confirmed by screenshot, including an organic HP drop (200→166, exactly Ruin Slam's 34 damage) between the two telegraph captures.
- `godot-gdscript-specialist` verdict: **APPROVE WITH NOTES**. Confirmed the subclass approach is sound line-for-line against `Enemy._begin_attack()` and confirmed `stats.attack` is genuinely unused for gameplay (only an unused debug-assert fallback). One real should-fix found and applied+reverified: `_choose_pattern()`'s `roll <= cumulative` boundary let `roll == 0.0` select an excluded (just-used, weight-0) pattern when it sat first in the list — an astronomically rare (~1-in-4-billion-per-roll) RNG outcome that would briefly violate "never repeats back-to-back." Fixed by explicitly skipping zero-weight candidates in the selection loop rather than relying on the boundary; verified both in isolation (forced `roll=0.0` against the exact flagged weight pattern) and via a 6-attack regression run (still strict alternation, no repeats). Also added an `assert` guarding an empty `attack_patterns` array (nice-to-have, matches the project's existing debug-assert convention for similar preconditions).
- Remaining nice-to-have (not applied, not blocking): `boss_arena.gd`'s signal-callback methods appear before its private helpers, inverting the project's usual section order (cosmetic, test-scaffolding file only).

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

**Status**: [x] Created — `production/qa/evidence/story-004-mini-boss/01-boss-spawned.png`, `02-telegraph-mini_boss_ruin_slam.png`, `03-telegraph-mini_boss_quick_slash.png`. Unit/integration test waived (advisory) at `qa.level: minimal` — the required "test file OR playtest note" is satisfied by this evidence + the orchestrator's scripted verification; not written as a `tests/` file.

---

## Dependencies

- Depends on: Story 003
- Unlocks: Story 005, Story 006

---

## Completion Notes
**Completed**: 2026-10-01
**Criteria**: 6/6 passing, none deferred. Telegraph/pattern logic verified correct by script and screenshot; the owner's playtest flagged that placeholder shapes (no real sprites yet) make reading the boss's state/attacks harder than it will be with final art — an expected limitation of this stage, not a story defect (see tech debt below).
**Deviations**: None against the brief. No Story 003 file was touched.
**Test Evidence**: Integration — unit/integration test waived (advisory) at `qa.level: minimal`; screenshots + scripted verification satisfy the "test OR playtest note" requirement. Evidence in `production/qa/evidence/story-004-mini-boss/`.
**Code Review**: `godot-gdscript-specialist` reviewed (APPROVE WITH NOTES) — 1 should-fix applied and reverified (`_choose_pattern()` roll==0.0 boundary). `LP-CODE-REVIEW` skipped (solo mode).
**Carried forward (not tracked in the debt register)**: `boss_arena.gd` method ordering (cosmetic); from Story 003 — `state_changed`/`attack_phase_changed` unused listeners, `AttackTokenPool.max_tokens` write validation, `set_deferred` asymmetry, shared RNG instance, RingLayout ring-collapse limitation (still not applicable here — this story never used RingLayout).
