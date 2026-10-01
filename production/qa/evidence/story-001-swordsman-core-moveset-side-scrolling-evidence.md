# Test Evidence: Story 001 — Swordsman core moveset (side-scrolling rework)

> **Story**: `production/epics/ragnarok-brawler/story-001-swordsman-core-moveset.md`
> **Story Type**: Visual/Feel
> **Date**: 2026-10-01
> **Tester**: Claude (scripted windowed runs of the real game scene) — owner review pending, see Sign-Off
> **Build / Commit**: uncommitted working tree on `main` (base `b21fa0f`), Godot 4.7.2.stable.official.ed1daf0bf

---

## What Was Tested

This supersedes nothing from the first-pass evidence doc's attack/dodge/skill/death findings — those mechanics didn't change. This doc covers only what the rework touched: X-primary/depth-lane movement, horizontal camera scroll with edge clamping, jump (gravity-driven height axis), and an airborne attack. All run in a normal windowed Godot session (Vulkan/Forward+), launched into the real test scene. Input was simulated (`Input.action_press`/direct state inspection), not played by a human.

**Acceptance criteria covered**: the 4 rewritten criteria (lane movement, camera scroll, jump, airborne attack) + the 60fps criterion (re-measured for this pass). The other 7 criteria are unchanged from the first pass — see `story-001-swordsman-core-moveset-evidence.md` (marked SUPERSEDED for its framing narrative, not for those specific findings).

---

## Acceptance Criteria Results

| # | Criterion | Result | Notes |
|---|---|---|---|
| Lane | X is primary, Y confined to a narrow depth lane | PASS | Pushing `move_up` past the lane clamps `global_position.y` to exactly `430.0` (`lane_top`). |
| Camera | Scrolls horizontally, clamped to level bounds | PASS | `Camera2D.get_screen_center_position()` converges from 640→1399.95 within 2s of a teleport to world x=1400 (mid-level, correctly centered). At world x=2780 (near the 2800px level edge) it clamps to exactly 2160 — view range `[1520,2800]`, never showing past the level. At the start (x=220) it clamps to 640 — view `[0,1280]`. All three match the expected `Camera2D` limit math exactly. |
| Jump | Gravity-driven height axis, lands cleanly | PASS | Character visibly rises above its (grounded) shadow during `AIRBORNE`; `jump_height` rises then decays to 0 and the state returns to `IDLE` without intervention. |
| Airborne attack | At least one attack usable while airborne | PASS | Basic attack reaches `ACTIVE` phase and connects (target dummy 100→90 HP) while `jump_height=68.3` (still off the ground); lands cleanly afterward. |
| FPS | 60 fps in a real windowed run | PASS | 180.7 fps average over 240 real frames — well above budget. (Unchanged measurement method/result from the first pass; re-stated here since the scene itself changed.) |
| Heavy / dodge / skill / death (re-verified on the final build) | Mechanics carried over from the first pass still work after the rework and collision change | PASS | Re-run on the current build, windowed: heavy attack did 28 damage vs basic's 10 (distinct, screenshot 13); dodge turned i-frames on then off (14); skill did 40 damage with a 3.85 s cooldown shown in the HUD (15); 7 test hits took HP 200→0 and `State: DEAD` (16). FPS re-measured at 182.9. |
| Solid collision | Player cannot walk through target dummies | PASS | Added after the owner found this playing the build: dummies previously had only an `Area2D` hurtbox (no solid body). Player now stops at distance ≈22.1 (feet radius 8 + dummy solid radius 14) and does not tunnel through under sustained push. |

---

## Screenshots / Video

| # | Filename | What It Shows |
|---|----------|--------------|
| 06 | `story-001-swordsman-core-moveset/06-level-start.png` | Level start: camera clamped to the left edge, player and TargetDummyA visible |
| 07 | `story-001-swordsman-core-moveset/07-walked-camera-follows.png` | After walking right via real simulated input for 6s of physics time: camera has followed, TargetDummyA now trails behind on screen |
| 08 | `story-001-swordsman-core-moveset/08-camera-mid-level.png` | Player teleported to the level's middle: camera centers exactly on the player, TargetDummyB visible nearby |
| 09 | `story-001-swordsman-core-moveset/09-camera-right-edge-clamped.png` | Player near the level's right edge: camera clamped, player pushed toward the screen's right edge rather than staying centered — the level boundary is visible as intended |
| 10 | `story-001-swordsman-core-moveset/10-jump-airborne.png` | `State: AIRBORNE` — character drawn clearly above its grounded shadow |
| 11 | `story-001-swordsman-core-moveset/11-airborne-attack-connects.png` | `State: BASIC_ATTACK / Phase: ACTIVE` while still airborne — hitbox overlapping the dummy, hit-flash visible, character still elevated above its shadow |
| 12 | `story-001-swordsman-core-moveset/12-solid-collision-blocked.png` | Player walked at a dummy and stopped adjacent to it (not overlapping) — solid collision confirmed |
| 13 | `story-001-swordsman-core-moveset/13-heavy-attack-connects.png` | `HEAVY_ATTACK / ACTIVE`, larger orange hitbox on the dummy, hit flash, dummy HP bar reduced |
| 14 | `story-001-swordsman-core-moveset/14-dodge-iframes.png` | `State: DODGE`, character translucent and blue-tinted (i-frames) |
| 15 | `story-001-swordsman-core-moveset/15-skill-active-cooldown.png` | `SKILL / ACTIVE`, big hitbox and burst, `Skill [L]: cooldown 3.9s` |
| 16 | `story-001-swordsman-core-moveset/16-player-dead.png` | `State: DEAD`, fallen character, `HP 0 / 200` |

---

## Test Conditions

- **Game state at start**: fresh `test_arena.tscn`, player at spawn (220, 500), level width 2800px, depth lane y∈[430,570]
- **Platform / hardware**: Windows 11 Pro, AMD Radeon RX 9070 XT, 1280x720 window
- **Framerate during test**: ~181 fps average (normal windowed run)
- **Any special setup required**: scripted `-s` runs simulating input and, for the camera checks, teleporting the player to specific world positions to confirm the clamp/follow math at both extremes without waiting out the (currently slow-feeling, see Observations) walk speed

---

## Observations

- **Verification methodology bug (mine, not the game's), caught before trusting the result**: my first pass at this verification counted `SceneTree.process_frame` (rendered frames, running uncapped at ~180fps here) as a proxy for elapsed physics time, producing two screenshots that looked like the camera wasn't following the player at all — it was, just not yet converged after the (much shorter than assumed) real time that had actually elapsed. Redone using `physics_frame` (fixed 60Hz), which is what `_physics_process` — where the camera-follow code lives — actually runs on. The two misleading screenshots were deleted, not kept. Recorded here because it's the same failure shape the project's own rules warn about in the *implementation* (a check that didn't really run looking identical to one that passed) — this time it was in my own verification step.
- **Move speed feels slow for a level this wide**: at `stats.move_speed=220px/s`, crossing the full 2800px level takes ~13 real seconds — walking it in the demo took several real seconds just to leave the starting screen. Not a story defect (the camera/lane/jump mechanisms are all confirmed correct independent of speed, via the teleport tests), but worth a tuning pass once the level length is closer to final — flagging for the owner, not fixing unasked since it's a feel/balance call, not a correctness one.
- A `godot-gdscript-specialist` review of the rework found one real should-fix bug (hurt-recovery while airborne always returned to `IDLE` instead of possibly `AIRBORNE`) — fixed and reverified (see the story's Implementation Notes for the before/after). No blocking issues.
- Heavy attack, dodge, skill, and death were first verified before the rework; since `swordsman.gd` changed afterwards they were re-run on the final build at `/story-done` time (screenshots 13–16) rather than closing on carried-over evidence.
- Hit-stop and knockback *feel* is still a human judgement; the owner played the build and approved it (see Sign-Off).

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead (art-director / designer) | Project owner | 2026-10-01 | [x] Approved |

*Sign-off basis: the owner played the build directly (not just the screenshots) across two sessions — the side-scrolling rework and the solid-collision fix — and confirmed "ficou bom" after the collision fix specifically.*

---

*Template: `.claude/docs/templates/test-evidence.md`*
*Used for: Visual/Feel and UI story type evidence records*
*Location: `production/qa/evidence/[story-slug]-evidence.md`*
