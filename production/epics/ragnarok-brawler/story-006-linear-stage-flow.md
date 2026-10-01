# Story 006: Linear stage and win/lose flow

> **Epic**: Ragnarok Brawler (MVP)
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: TBD
> **Manifest Version**: N/A (minimal — no control manifest)
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/game-brief.md`
**Requirement**: Brief MVP feature 7 (1 linear stage) + Player goal & fail state

**ADR Governing Implementation**: N/A (minimal — no ADRs)
**ADR Decision Summary**: N/A (minimal — no ADRs)
**ADR Version**: N/A (minimal — no ADRs)

**Engine**: Godot 4.7.2 | **Risk**: HIGH (docs/engine-reference/godot/VERSION.md — 4.7 row)
**Engine Notes**: none (no ADR engine-compatibility analysis at minimal)

**Control Manifest Rules (this layer)**: N/A (minimal — no control manifest)

---

## Acceptance Criteria

*From `design/game-brief.md` (Player goal & fail state + MVP feature 7), scoped to this story:*

- [ ] One linear stage runs start to finish: encounter groups → mini boss → more encounters → boss
- [ ] The next encounter only starts when the previous group is cleared (using Story 003's cleared signal)
- [ ] The stage uses an original pixel-art tileset/background (PixelLab) or marked placeholders
- [ ] **Win**: defeating the boss ends the stage with a clear "stage complete" state
- [ ] **Fail**: player HP reaching 0 shows a defeat state and restarts the stage
- [ ] A restart fully resets the stage (enemies, boss, player HP) with no leftover state
- [ ] The stage is startable from launch (set as `run/main_scene` in `project.godot`) and playable end to end in one sitting
- [ ] Holds 60 fps through the busiest encounter

---

## Implementation Notes

- This is the glue story: it wires Stories 001–005 together, so it is also the first time the whole game is run
- Set `run/main_scene` in `project.godot` here (it is deliberately unset today)

---

## Out of Scope

- Menus, save/load, multiple stages, progression between runs

---

## QA Test Cases

*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*

---

## Test Evidence

*Governed by `qa.level: minimal`: tests are waived, but a retained screenshot is required for the run-and-observe check (coding standards).*

**Story Type**: Integration
**Required evidence**: `tests/integration/stage/stage_flow_test.gd` OR a playtest note (advisory), plus a retained screenshot of the stage running in `production/qa/evidence/`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003, Story 004, Story 005
- Unlocks: None
