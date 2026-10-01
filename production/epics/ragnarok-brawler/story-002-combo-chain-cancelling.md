# Story 002: Combo chain with animation cancelling

> **Epic**: Ragnarok Brawler (MVP)
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: TBD
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-01

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

- [x] Pressing basic attack repeatedly chains a multi-hit combo; timing outside the input window resets it — OBSERVED: step0→step1→step2 chained correctly (damage 10→12→20), a press after the chain window elapses (or after step2 ends) starts a fresh combo at step0 (screenshot 01)
- [x] A heavy attack can end or branch a combo — OBSERVED: heavy pressed inside any step's chain window branches into the finisher (28 dmg) and ends the combo (`get_combo_step()` returns NO_STEP); next basic press starts step0 fresh
- [x] Defined cancel windows let the player cancel an attack into dodge or the special skill — OBSERVED: dodge/skill press after `AttackData.cancel_window_start` is reached transitions immediately (screenshot 02); a press made *before* the window is buffered and fires the instant the window opens (confirmed frame-by-frame)
- [x] Cancelling cuts the remaining recovery of the cancelled animation — OBSERVED: state changed to DODGE well before the attack's `get_total_duration()` would have elapsed
- [x] Combo and cancel rules are data-driven (windows, chain order, damage per hit) — all in `assets/data/combo/swordsman_combo.tres` and per-attack `cancel_window_start`; confirmed by `godot-gdscript-specialist` grep
- [x] A combo counter is tracked and resets on timeout or when the player is hit — OBSERVED: +1 per connected hit, resets to 0 after 0.8s idle and immediately on taking damage
- [x] Combos remain responsive: input pressed in a window is never dropped — OBSERVED: a press during the player's OWN hit-stop (from landing a hit) is buffered, does not age while frozen, and fires exactly on the physics tick where the chain window opens after unfreezing; a cancel press made while the target move is on cooldown stays buffered and either fires once cooldown clears (if within the 0.2s buffer) or silently expires (if not) — never fires late

---

## Implementation Notes

- Model the attack/combo/cancel logic as a state machine separate from presentation, so it can be unit-tested without rendering
- Reuse the moveset from Story 001; this story adds chaining, not new moves

**Design (2026-10-01):** `ComboController` (`src/gameplay/combo_controller.gd`) is a pure `RefCounted` — no Node, no Input access — holding the input buffer, chain windows, heavy-finisher branch, cancel windows and combo counter. `Swordsman` feeds it presses (captured in `_input()`, ahead of the hit-stop early-return in `_physics_process`, so a press during hit-stop is never lost) and elapsed time, and performs the state changes it returns. 3-hit basic chain (10/12/20 damage, chain windows 0.18–0.34s / 0.16–0.36s / 0.22–0.50s into each step), heavy branch reachable from any step, cancel windows open at a per-attack `cancel_window_start` and stay open through recovery, 0.8s combo timeout, 0.2s input buffer. Data in `assets/data/combo/swordsman_combo.tres` + `cancel_window_start` on each `AttackData` `.tres`.

**Post-implementation note (orchestrator + godot-gdscript-specialist review, 2026-10-01):**
- `godot-gdscript-specialist` verdict: **APPROVE WITH NOTES**. One should-fix applied and reverified: `_try_combo_action()`'s CHAIN/HEAVY_FINISHER branches set `_queued_attack`/`_queued_step` before calling `_change_state()` without checking its return value — if the transition were ever rejected, the queued attack would leak into a later, unrelated `_begin_attack()` call. Not reachable with today's `TRANSITIONS` table, but fixed to mirror the existing defensive pattern in `_start_basic_attack()` (clear the queue on a failed transition). Re-verified: chain (10+12+20) and heavy finisher (fresh step0 afterward) both still correct post-fix.
- Remaining nice-to-haves (not applied, not blocking): `BufferedPress.button`/`_init` typed `int` instead of `ComboController.PressKind`; hardcoded sword-swing angles in the placeholder visual (cosmetic only); carried over from Story 001 (untyped `TRANSITIONS`, unguarded `state` writes, file-section-order drift).
- Orchestrator's own independent verification (frame-accurate scripted runs, not the implementing agent's self-report) hit several apparent anomalies that all traced back to the verification script's own timing (confusing render-frame waits with physics-tick waits), not implementation bugs — each was redone correctly and confirmed. Recorded as a reminder that a verification script needs the same scrutiny as the code it checks.

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

**Status**: [x] Created — `production/qa/evidence/story-002-combo-chain-cancelling/01-combo-step3-active-counter.png`, `02-heavy-cancelled-into-dodge.png`. Unit test waived (advisory) at `qa.level: minimal` per Test Evidence above — not written.

---

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003

---

## Completion Notes
**Completed**: 2026-10-01
**Criteria**: 7/7 passing, none deferred. Feel (buffer/window timing) confirmed by the owner playing the build ("ficou bom").
**Deviations**: None against the brief.
**Test Evidence**: Logic — unit test waived (advisory) at `qa.level: minimal`, not written. Screenshots in `production/qa/evidence/story-002-combo-chain-cancelling/`.
**Code Review**: `godot-gdscript-specialist` reviewed (APPROVE WITH NOTES) — one should-fix applied and reverified (`_queued_attack`/`_queued_step` leak on a rejected combo transition, fixed to mirror `_start_basic_attack()`'s pattern). `LP-CODE-REVIEW` skipped (solo mode).
**Carried forward (not tracked in the debt register)**: `BufferedPress.button`/`_init` typed `int` instead of `ComboController.PressKind`; hardcoded sword-swing angles in the placeholder visual (cosmetic); from Story 001 — untyped `TRANSITIONS`, unguarded `state` writes, file-section-order drift, `move_speed` may feel slow on a 2800px level.
