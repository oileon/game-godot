# Game Brief: Ragnarok Brawler (working title)

**One-sentence pitch:** A pixel-art beat 'em up inspired by Ragnarok — Ragnarok Battle Offline's fast, combo-driven arcade combat combined with Ragnarok Online's class and sprite aesthetic — where you tear through hordes with combos, dodges and skills on the way to a mini boss and a boss.

**Genre/perspective (clarified 2026-10-01):** a classic side-scrolling beat 'em up, like RBO itself — not top-down. Movement: horizontal (left/right) is the primary axis the camera scrolls with; up/down is a narrow depth "lane", not full-screen freedom. Jump and aerial attacks/combos exist (gravity-driven height axis, separate from the depth lane). The first implementation pass (Story 001) guessed top-down/free-roam and had to be corrected — recorded here so later sessions don't repeat the guess.

## Core loop
<!-- The cycle the player repeats. What they do → what they get → why they do it again. 2–4 bullets. -->
- Engage a group of enemies → chain combo/cancel attacks to control the horde → dodge or stagger when pressured → clear the group → advance to the next encounter → repeat until mini boss → boss.

## Player goal & fail state — what "working" looks like
<!-- What the player is trying to achieve (the win, the score, or the point) and how a run ends or fails. Even a cozy or sandbox game has a "a session feels complete when…". This is the one field your stories' ACCEPTANCE CRITERIA trace back to — it turns "the game works" into something testable. One or two lines. -->
- Goal: clear the full stage by defeating the boss. Fail: HP reaches 0 and the stage restarts (no permadeath / no run-based meta — this MVP proves combat, not a roguelite loop).

## MVP — what must exist to be the game
<!-- The ruthlessly short list of features without which this ISN'T the game yet. Each one becomes a story. Longer than ~7 and it's not an MVP. -->
- 1 playable class in the Swordsman archetype (Ragnarok Online–style starting melee class: high HP, physical damage) — original name and sprite, built in PixelLab
- Basic attack + heavy attack + dodge + 1 special skill
- Combo system with animation cancelling
- 3–5 common enemy types
- 1 mini boss
- 1 boss with at least 2 phases
- 1 linear stage stringing the encounters together

## Out of scope — not building this
<!-- What you're deliberately NOT doing. The list that saves the project. Be specific: "no multiplayer", "no save system", "one level only". -->
- No multiplayer / co-op
- No classes beyond the first
- No equipment or loot system
- No exploration or secrets
- No persistent progression between runs
- No story or dialogue beyond minimal framing
- No reuse of Ragnarok's own trademarked character, monster, or asset names/designs — inspiration is stylistic, not a clone

## Build order
<!-- The sequence to build the MVP. Risky / core-fun thing FIRST — prove it's fun before you polish. -->
1. Movement + basic attack feel
2. Combo system with animation cancelling
3. Group enemy AI (horde behavior)
4. Mini boss
5. Boss with phases
6. Stitch encounters into the linear stage

---
<!-- RECOMMENDED — one line each, delete a line only if it's truly N/A for this game. -->
**Who it's for / what they feel:** fans of fast arcade brawlers who want tight, combo-driven combat in short, intense sessions.

**Art & audio direction:** pixel art in a Ragnarok Online–inspired style — chibi proportions, vibrant palette, colorful towns — generated with PixelLab; no reuse of official sprites or names. Punchy, "crunchy" hit-feedback SFX per attack.

**Reference game:** Ragnarok Battle Offline (combat pacing and depth) + Ragnarok Online (class/sprite visual identity). The MVP keeps ~10%: one Swordsman-style class, one stage, no multiplayer/equipment yet — all original assets inspired by the style, not copied.
