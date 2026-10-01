> **SUPERSEDED 2026-10-01.** This evidence verifies a top-down/free-roam
> movement model. The owner reviewed the build and corrected the genre to a
> classic side-scrolling beat 'em up (horizontal primary axis, narrow depth
> lane, camera scroll, jump/aerial attacks) — see `design/game-brief.md`'s
> "Genre/perspective (clarified 2026-10-01)" note and the story's rewritten
> acceptance criteria. Kept for history; do not use this to sign off on the
> reworked story. New evidence lives alongside this file once the rework is
> re-verified.

# Test Evidence: Story 001 — Swordsman core moveset (top-down pass — superseded)

> **Story**: `production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-10-01
> **Tester**: Claude (scripted windowed runs of the real game scene) — owner review pending, see Sign-Off
> **Build / Commit**: uncommitted working tree on `main` (base `b21fa0f`), Godot 4.7.2.stable.official.ed1daf0bf

---

## What Was Tested

The Swordsman's core moveset in `res://src/gameplay/player/test_arena.tscn`: movement, basic/heavy attack phases, dodge with i-frames, the special skill with cooldown, hit feedback on target dummies, HP and death. Everything ran in a normal windowed Godot session (Vulkan / Forward+), launched straight into the test scene. Input was simulated with `Input.action_press` (the same actions the keyboard and mouse bindings trigger); no human played it.

**Acceptance criteria covered**: AC-1 … AC-9

---

## Acceptance Criteria Results

| # | Criterion (from story) | Result | Notes |
|---|----------------------|--------|-------|
| AC-1 | A playable Swordsman character moves around the stage's 2D play space with keyboard/mouse input | PASS (input map + simulated input) | `move_right` held 30 frames moved the player dx=36.7 px. Physical bindings decoded from `project.godot`: W/A/S/D and arrow keys move, J / left mouse = basic, K / right mouse = heavy, Space = dodge, L = skill. A human pressing real keys was not part of this run. |
| AC-2 | Basic attack and heavy attack are distinct, with clear start-up/active/recovery timing | PASS | Screenshot 02 is mid-ACTIVE (`Phase: ACTIVE`, live hitbox shown). Timings come from separate `.tres` files. Heavy attack was exercised by the implementing agent's headless run, not captured here. |
| AC-3 | Dodge moves the character a short distance and grants brief invulnerability | PASS | `invulnerable=true` 7 frames after pressing dodge, back to `false` and `State: IDLE` when it ended. Screenshot 03 shows the i-frame tint. |
| AC-4 | One special skill is usable, with a visible cost or cooldown | PASS | Skill hit for 40 damage (100→60); HUD shows `Skill [L]: cooldown 3.9s` with a filling bar (screenshot 04). |
| AC-5 | Attacks damage a test target and produce impact feedback (hit-stop, knockback, hit effect) | PASS | Damage 100→90 (basic), 100→60 (skill). Hit-stop measured: attacker frozen up to 0.06 s (12 frames). Knockback: dummy displaced 8.3 px by the basic attack, ~60 px visible after the skill (screenshots 04→05). Hit flash and burst visible in 02 and 04. How it *feels* is not judged here. |
| AC-6 | Character has HP, takes damage, and reaches a death state at 0 HP | PASS | 7 test hits took HP 200→0 and `State: DEAD`; screenshot 05 shows the fallen body and `HP 0 / 200`. |
| AC-7 | Original pixel-art sprites (PixelLab) or clearly marked placeholders; no official Ragnarok assets or names | PASS | All visuals are code-drawn shapes, labelled PLACEHOLDER in source. No sprites yet. |
| AC-8 | Gameplay values are data-driven, not hardcoded | PASS | Reviewed by `godot-gdscript-specialist`: all combat tunables are in `assets/data/**.tres`; the only literal is the arena's `play_area` geometry. |
| AC-9 | Runs at 60 fps on the dev machine in the test scene | PASS | 181.3 fps average over 240 frames in a normal windowed run (not Movie Maker). The HUD reading 32–54 fps in screenshots 01–02 was Movie Maker encoding overhead. |

---

## Screenshots / Video

| # | Filename | What It Shows | Acceptance Criterion |
|---|----------|--------------|----------------------|
| 1 | `story-001-swordsman-core-moveset/01-idle-scene-player-and-dummies.png` | Swordsman and three target dummies rendered at their positions, HUD legible | AC-7 |
| 2 | `story-001-swordsman-core-moveset/02-basic-attack-connects-hit-flash.png` | Basic attack in ACTIVE phase with the hitbox overlapping a dummy, white hit flash | AC-2, AC-5 |
| 3 | `story-001-swordsman-core-moveset/03-dodge-iframes.png` | `State: DODGE`, Swordsman translucent and blue-tinted (i-frames) | AC-3 |
| 4 | `story-001-swordsman-core-moveset/04-skill-active-cooldown.png` | `State: SKILL / ACTIVE`, large hitbox, burst effect, dummy HP bar reduced, `Skill [L]: cooldown 3.9s` | AC-4, AC-5 |
| 5 | `story-001-swordsman-core-moveset/05-player-dead.png` | `State: DEAD`, fallen Swordsman, `HP 0 / 200` | AC-6 |

---

## Test Conditions

- **Game state at start**: fresh `test_arena.tscn`, player at spawn (320, 460), three dummies, full HP
- **Platform / hardware**: Windows 11 Pro, AMD Radeon RX 9070 XT, 1280x720 window
- **Framerate during test**: ~181 fps average (normal windowed run); vsync state not recorded
- **Any special setup required**: scripted runs via `-s` scripts that instance the scene and simulate input; the player was repositioned next to a dummy for the attack and skill captures

---

## Observations

- A first capture of screenshot 01 showed no character or dummies. Cause: the placeholder visuals' typed-Node `@export` wired as `NodePath("..")` stayed `null` on instantiate, so `_draw()` never ran. Fixed with a `get_parent()` fallback in both visual scripts and re-verified.
- Heavy attack and the exact feel of hit-stop and knockback (timing, weight, responsiveness) were not judged by a human; a still and a few numbers cannot show them. Candidate for `/team-qa` or a playtest.
- `godot-gdscript-specialist` review: APPROVE WITH NOTES. Nice-to-haves recorded in the story's Implementation Notes.

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | | | [ ] Approved |

*Owner confirmed screenshots 01–02 earlier today ("continue"). Screenshots 03–05 and the measurements were added afterwards and have not been reviewed by the owner yet.*

---

*Template: `.claude/docs/templates/test-evidence.md`*
*Used for: Visual/Feel and UI story type evidence records*
*Location: `production/qa/evidence/[story-slug]-evidence.md`*
