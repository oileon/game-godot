# Story 001: Swordsman core moveset

> **Epic**: Ragnarok Brawler (MVP)
> **Status**: Complete
> **Layer**: Core
> **Type**: Visual/Feel
> **Estimate**: TBD
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: 2026-10-01

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 1–2 (Swordsman-style class; basic attack, heavy attack, dodge, 1 special skill)

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md — 4.7 row)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Player goal & fail state + MVP features 1–2 + the 2026-10-01 genre/perspective clarification), scoped to this story:*

**Superseded 2026-10-01 — see note below.** The checkmarks below were earned
against a top-down/free-roam movement model. The owner corrected this after
reviewing the build: Ragnarok Brawler is a **classic side-scrolling beat 'em
up** (like RBO itself), not top-down. Re-opened; criteria rewritten for the
corrected model. The old evidence (screenshots 01–05) is superseded, not
deleted — see `production/qa/evidence/story-001-swordsman-core-moveset-evidence.md`.

- [x] A playable Swordsman character moves left/right as the primary axis; up/down movement is confined to a narrow depth "lane", not full-screen freedom — OBSERVED: lane clamps exactly at y=430 (lane_top) when pushed beyond it (evidence 06–09)
- [x] The camera scrolls horizontally, following the player across a level wider than one screen, clamped to the level's bounds — OBSERVED: `get_screen_center_position()` converges to the player's X (640→1399.95 within 2s), clamps exactly at the level edges (640 left, 2160 right for a 2800px level) (evidence 06–09)
- [x] The character can jump (gravity-driven height axis, separate from the depth lane) and land cleanly — OBSERVED: character draws visibly elevated above its grounded shadow, lands cleanly back to IDLE (evidence 10)
- [x] At least one attack (basic, heavy, or skill) can be used while airborne — OBSERVED: basic attack connects while airborne (dummy 100→90 HP, jump_height=68.3 at the moment of the hit) (evidence 11)
- [x] The player cannot walk through target dummies (solid collision, not just hit detection) — added 2026-10-01 after the owner found the gap by playing the build; OBSERVED: player stops at distance ≈22.1 (sum of collision radii) and does not tunnel through under sustained input (evidence 12)
- [x] Basic attack and heavy attack are distinct, with clear start-up/active/recovery timing — unchanged from the first pass, previously OBSERVED
- [x] Dodge moves the character a short distance and grants brief invulnerability — unchanged from the first pass, previously OBSERVED
- [x] One special skill is usable, with a visible cost or cooldown — unchanged from the first pass, previously OBSERVED
- [x] Attacks damage a test target and produce impact feedback (hit-stop, knockback, hit effect) — unchanged from the first pass, previously OBSERVED; re-confirmed for the airborne case in evidence 11
- [x] Character has HP, takes damage, and reaches a death state at 0 HP — unchanged from the first pass, previously OBSERVED
- [x] Character uses original pixel-art sprites (PixelLab) or clearly marked placeholders; no official Ragnarok assets or names — OBSERVED throughout evidence 06–11
- [x] Gameplay values (speed, damage, timings, cooldowns, jump/gravity) are data-driven, not hardcoded — `jump_velocity`/`jump_gravity` added to `SwordsmanStats`/`swordsman_stats.tres`; confirmed by `godot-gdscript-specialist` review
- [x] Runs at 60 fps on the dev machine, measured in a real windowed run (not a Movie Maker capture) — 180.7 fps average, normal windowed run

---

## Implementation Notes

- Build this first and tune until attacking feels good — the brief's riskiest, most important thing
- Keep tuning values in external config (coding standards)
- Placeholder art is fine at first; swap in PixelLab sprites without changing logic

**Post-implementation note (orchestrator + godot-gdscript-specialist review, 2026-10-01, first pass — top-down model, now superseded):**
- Bug found and fixed during run-and-observe: `SwordsmanPlaceholderVisual.actor` / `TargetDummyPlaceholderVisual.target` (typed-Node `@export`s wired via `NodePath("..")` in `.tscn`) did not auto-resolve on instantiate — stayed `null`, so nothing rendered. Fixed with a `_ready()` `get_parent()` fallback in both files. No other instance of this pattern found elsewhere in the codebase (specialist grepped for it). **This fix still applies after the rework** — it is a general Godot wiring fix, not specific to the movement model.
- `godot-gdscript-specialist` verdict on the first pass: **APPROVE WITH NOTES**, no blocking issues. Nice-to-have, still worth revisiting in Story 002: type the `TRANSITIONS` dictionary (`Dictionary[State, Array[State]]` — unverified against 4.7.2 docs, confirm before applying); consider guarding `Swordsman.state` against direct external writes (currently enforced only by convention); minor file-section-order drift against the coding-standards file-organization convention; `AttackData.move_name` is currently unread (presumably for Story 002).

**Bug found by the owner playing the build (2026-10-01, third pass):** target dummies had only an `Area2D` hurtbox (no solid body) and the player's `CharacterBody2D` had `collision_mask=0` — the player walked straight through every dummy. Fixed: `TargetDummy`'s root changed from `Node2D` to `StaticBody2D` with a new `SolidCollision` `CircleShape2D` (radius 14) on a new `collision_layer=8` (distinct from the existing hurtbox/hitbox layers 1/2/4); `Swordsman.collision_mask` changed from `0` to `8`. Verified: player walking at a dummy stops at `distance ≈ 22.1` (= player's feet radius 8 + dummy's solid radius 14, i.e. the shapes are touching, not overlapping) and stays there even when pushed for longer — does not tunnel through. Screenshot: `production/qa/evidence/story-001-swordsman-core-moveset/12-solid-collision-blocked.png`. No post-4.3 API involved (`StaticBody2D`, `CircleShape2D`, `collision_layer`/`collision_mask` are long-stable); reviewed by the orchestrator only, not re-spawned to the specialist given the narrow, numerically-verified scope — flagged here so that omission is visible rather than silent.

**Rework note (2026-10-01, second pass — corrected to side-scrolling):**
- Movement model corrected to a classic side-scrolling beat 'em up: X is the primary camera-following axis; Y is a narrow depth lane (not full-screen freedom); a new height axis (gravity, jump, landing) is separate from both. At least one attack must work while airborne. A Camera2D now follows the player horizontally across a level wider than one screen.
- The locomotion rewrite, camera, and jump are new work on top of the first pass's combat/health/hit-feedback logic, which is retained as-is (attacks, hit-stop, knockback, hurtbox/hitbox, HealthComponent did not need to change for this correction).
- The implementing agent hit its turn limit once mid-task and was resumed to finish and verify — flagged here per the project's own rule that a step which could not run must say so, not read as done by default.
- The orchestrator's own first verification pass was itself mistimed (counted rendered frames at ~180fps instead of fixed 60Hz physics ticks), producing two misleading screenshots that looked like the camera wasn't following at all. Caught before accepting it, redone correctly — worth recording since it's the same "a check that doesn't run looks identical to one that passed" trap this project's rules warn about, just one level up (in the verification, not the implementation).
- `godot-gdscript-specialist` review of the rework: **APPROVE WITH NOTES** → one should-fix applied and reverified: hurt-recovery while airborne (`_process_hurt`) always resolved to `IDLE` instead of `_landing_state()`, and `TRANSITIONS[HURT]` didn't list `AIRBORNE` — a hit taken mid-air let the player then use ground-only moves (heavy/skill/dodge) while still visibly airborne. Fixed (two lines: `swordsman.gd` `TRANSITIONS[HURT]` now includes `AIRBORNE`; `_process_hurt()` now calls `_landing_state()`) and reverified — hit-while-airborne now correctly returns to `AIRBORNE` when still off the ground, hit-while-grounded still correctly returns to `IDLE`. Remaining nice-to-haves (carried over, still not blocking): untyped `TRANSITIONS`, unguarded `state` writes, file-section-order drift, a cosmetic 4.7 line-AA change in the placeholder visual, a jump-velocity-before-state-change ordering nit.

---

## Out of Scope

- Story 002: chaining attacks into combos and animation cancelling
- Story 003: real enemies and AI

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived, but a Visual/Feel story's retained screenshot is not.*

**Story Type**: Visual/Feel
**Required evidence**: a retained screenshot in `production/qa/evidence/` showing the character attacking a target + sign-off in `production/qa/evidence/story-001-swordsman-core-moveset-evidence.md`

**Status**: [x] Created — `production/qa/evidence/story-001-swordsman-core-moveset/06-level-start.png` through `11-airborne-attack-connects.png` (the side-scrolling model: lane, camera, jump, airborne attack); sign-off doc at `production/qa/evidence/story-001-swordsman-core-moveset-side-scrolling-evidence.md` (lead sign-off pending — solo project, needs the owner's own look). Screenshots 01–05 (unchanged first-pass mechanics: basic/heavy attack, dodge, skill, death) are kept on disk and still cited — only their top-down framing/camera is stale, not the mechanics they show; the first-pass evidence doc stays marked SUPERSEDED since its narrative is written against the old movement model.

---

## Dependencies

- Depends on: None
- Unlocks: Story 002

---

## Completion Notes
**Completed**: 2026-10-01
**Criteria**: 13/13 passing, none deferred. Heavy attack, dodge, skill and death were re-run on the final build at close time (screenshots 13–16) because `swordsman.gd` changed after their first verification.
**Deviations**: None against the brief. Advisory: files outside the story's stated scope were touched on purpose (`.gitignore` `*.import` line, `design/game-brief.md` perspective note, `project.godot` input/display). The solid-collision fix was not re-sent to `godot-gdscript-specialist` (narrow, numerically verified, no post-4.3 API).
**Test Evidence**: Visual/Feel — evidence doc `production/qa/evidence/story-001-swordsman-core-moveset-side-scrolling-evidence.md` (sign-off `[x] Approved`, owner played the build); screenshots 01–16 in `production/qa/evidence/story-001-swordsman-core-moveset/`. Unit tests waived at `qa.level: minimal`.
**Code Review**: `godot-gdscript-specialist` reviewed twice (APPROVE WITH NOTES both times); `LP-CODE-REVIEW` skipped (solo mode).
**Carried forward (not tracked in the debt register)**: untyped `TRANSITIONS`, `state` writable from outside `_change_state()`, file-section-order drift, unused `AttackData.move_name`, `move_speed` 220 px/s may feel slow on a 2800 px level.
