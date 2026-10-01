class_name MiniBoss
extends Enemy
## Solo 1v1 mini-boss. Reuses Enemy's full state machine, hit-stop, hurtbox/
## hitbox and HealthComponent/KnockbackMotion plumbing UNCHANGED (enemy.gd is
## not modified), and adds the one thing a boss needs that a common enemy
## does not: a choice between several attack patterns (BossStats) instead of
## a single `stats.attack`.
##
## This is the "dress rehearsal" for Story 005's multi-phase boss: one phase
## with pattern VARIETY, not a phase system (out of scope here).
##
## Implements: design/game-brief.md MVP feature 5 (1 mini boss).
## Story: production/epics/ragnarok-brawler/story-004-mini-boss.md
##
## --- Design choice: subclass + override, not a shared-field generalisation ---
## Rather than generalising Enemy.stats.attack into an Array on EnemyStats
## (which would touch the already-reviewed Story 003 enemy.gd/enemy_stats.gd/
## enemy.tscn), this subclass overrides the one method that reads
## `stats.attack` for gameplay purposes: `_begin_attack()`. A grep of enemy.gd
## confirms `stats.attack` is referenced in exactly two places: the
## `_ready()` assert (satisfied by BossStats.attack - see its doc comment -
## a harmless fallback MiniBoss never actually uses for gameplay) and
## `_begin_attack()` (overridden below, in full, picking from
## `BossStats.attack_patterns` instead). No other Enemy method reads
## `stats.attack`, so no further override is needed: APPROACH/WAIT_RING still
## decide WHEN to attack purely from the shared `attack_range`/
## `attack_stand_distance` fields (also inherited from EnemyStats), and
## whichever pattern is chosen supplies its own hitbox size/offset/reach once
## ATTACK begins - a wide/long "slam" pattern can out-reach `attack_range`
## via its own `hitbox_offset`/`hitbox_size`/`lunge_speed`, same as any
## AttackData already does.
##
## --- Pattern selection rule (AC2: "at least 2 attack patterns") ---
## See `_choose_pattern()`: weighted random, excluding whichever pattern was
## used last so the SAME pattern never repeats back-to-back. With exactly 2
## authored patterns (mini_boss.tres) that is a strict alternation once the
## fight starts - intentional: predictable enough for the player to learn in
## a "dress rehearsal" boss, while still reading as two different threats.
## `pattern_weights` is wired for Story 005 to reuse with 3+ patterns.
##
## --- Stagger / armor rule (AC4: "not stunlocked by combos") ---
## `armor_during_attack` (inherited EnemyStats field, read by Enemy's own
## `_on_hurtbox_hit_received` - not overridden here) is true for the WHOLE
## boss, covering both patterns: once ATTACK begins, neither hitstun nor
## knockback interrupts it, matching the Slagbrute precedent from Story 003.
## Outside of ATTACK (approaching/waiting) hits still land and the boss still
## visibly reacts, but `hitstun_scale`/`knockback_scale` are both well below 1
## (see mini_boss.tres) so combo spam between attacks staggers it briefly
## without ever juggling/locking it - it "reacts to hits but isn't a
## pushover," per the acceptance criterion.
##
## --- Defeat signal (AC5: "signals the stage to advance") ---
## `died` (inherited, fires exactly once - verified in Story 003) is
## sufficient on its own for Story 006 to listen to directly. `boss_defeated`
## below just re-emits it under a boss-specific name for call-site
## readability in a future stage script; it is optional, not a new
## coordination mechanism (no EncounterGroup-style coordinator is built for a
## single enemy).

## Re-emits `died` under a boss-specific name. Optional - `died` itself fires
## at the exact same moment and is equally valid to listen to.
signal boss_defeated(boss: MiniBoss)

## Index into `attack_patterns` used for the attack just started (-1 = none
## yet). Tracked so `_choose_pattern()` can exclude it next time.
var _last_pattern_index: int = -1


func _ready() -> void:
	var boss_stats: BossStats = stats as BossStats
	assert(boss_stats != null, "MiniBoss requires a BossStats resource (stats)")
	assert(boss_stats.attack_patterns.size() >= 2, "MiniBoss requires at least 2 attack_patterns")
	super._ready()
	died.connect(_on_died)


# --- Attack pattern selection (overrides Enemy._begin_attack) ---------------

## Identical to Enemy._begin_attack() except the attack chosen comes from
## BossStats.attack_patterns via _choose_pattern() instead of the single
## stats.attack.
func _begin_attack() -> void:
	var boss_stats: BossStats = stats as BossStats
	var chosen: AttackData = _choose_pattern(boss_stats)
	_current_attack = chosen
	_hit_targets.clear()
	_projectile_fired = false
	velocity = Vector2.ZERO
	if not stats.is_ranged():
		var shape: RectangleShape2D = _hitbox_shape.shape as RectangleShape2D
		shape.size = chosen.hitbox_size
		hitbox.position = Vector2(chosen.hitbox_offset.x * facing_x, chosen.hitbox_offset.y)
		hitbox.monitoring = true
	_attack_phase = AttackPhase.STARTUP
	attack_started.emit(_current_attack)
	attack_phase_changed.emit(_attack_phase)


## Weighted random pick from `boss_stats.attack_patterns`, excluding the
## pattern used last time (`_last_pattern_index`) so the same pattern never
## repeats back-to-back. Falls back to allowing a repeat only if every
## candidate would otherwise have zero weight (e.g. a single pattern). Uses
## Enemy's injected `_rng` (set via configure()), never global randf(), for
## the same determinism Story 003 relies on.
func _choose_pattern(boss_stats: BossStats) -> AttackData:
	var patterns: Array[AttackData] = boss_stats.attack_patterns
	assert(not patterns.is_empty(), "BossStats.attack_patterns must not be empty")
	if patterns.size() <= 1:
		_last_pattern_index = 0
		return patterns[0]
	var weights: Array[float] = boss_stats.pattern_weights
	var candidate_weights: Array[float] = []
	var total: float = 0.0
	for i: int in patterns.size():
		var w: float = weights[i] if i < weights.size() else 1.0
		if i == _last_pattern_index:
			w = 0.0
		candidate_weights.append(w)
		total += w
	if total <= 0.0:
		# Every candidate was excluded or weighted zero - allow a repeat
		# rather than divide by zero.
		candidate_weights.clear()
		total = 0.0
		for i: int in patterns.size():
			var w: float = weights[i] if i < weights.size() else 1.0
			candidate_weights.append(w)
			total += w
	var roll: float = _rng.randf_range(0.0, total)
	var cumulative: float = 0.0
	for i: int in patterns.size():
		if candidate_weights[i] <= 0.0:
			# Skip excluded/zero-weight candidates explicitly - relying on the
			# roll<=cumulative boundary alone let roll==0.0 select an excluded
			# weight-0 entry sitting first in the list (godot-gdscript-specialist
			# review, Story 004), repeating the just-used pattern on a ~1-in-4-
			# billion RNG outcome. Explicit skip removes the dependency on which
			# bucket happens to sit at that boundary.
			continue
		cumulative += candidate_weights[i]
		if roll <= cumulative:
			_last_pattern_index = i
			return patterns[i]
	_last_pattern_index = patterns.size() - 1
	return patterns[_last_pattern_index]


func _on_died(_enemy: Enemy) -> void:
	boss_defeated.emit(self)
