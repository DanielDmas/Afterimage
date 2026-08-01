## The truth-layer simulation (master_plan.md §5.2): fixed-tick, integer-
## only, engine-agnostic. Pass 3 scope started deliberately narrow — one
## player-controlled Actor, collision-resolved movement only. Pass 7 wires
## in everything Pass 4-6 built standalone (LineOfSight/SoundGraph,
## VisionCone/AiAgent, MovementProfile/Weapon/CombatResolver/FocusState):
## AI actors now perceive and fight back, the player's combat verbs
## actually resolve. TruthSim.step() keeps its Pass 3 signature (advance
## one tick from one InputFrame) exactly as promised — every new verb is a
## new optional InputFrame key, not a breaking change to move_x/move_y's
## contract.
class_name TruthSim
extends RefCounted

const DEFAULT_PLAYER_HIT_POINTS: int = 3  # master_plan §4.9: "player takes 2-4 hits"
const DEFAULT_AI_HIT_POINTS: int = 2  # master_plan §4.9: "enemies take 1-3"
const HIT_DAMAGE: int = 1  # v0 simplification: every resolved hit costs exactly 1 hit point
const GROUND_OBSERVED_SUSPICION_WEIGHT: int = 2  # master_plan §4.7's own example weight

var clock: FixedTickClock
var grid: CollisionGrid
var actors: ActorRegistry
var player_id: int

var _event_bus: EventBus
var _ai_agents: Dictionary = {}  ## int actor_id -> AiAgent
var _weapons: Dictionary = {}  ## int actor_id -> Weapon
var _focus: FocusState
var _ground: GroundState
var _last_tick_sound_events: Array = []


func _init(
	cell_size_mm: int,
	start_position: Vector2i,
	player_radius_mm: int,
	event_bus: EventBus = null,
	player_hit_points: int = DEFAULT_PLAYER_HIT_POINTS
) -> void:
	clock = FixedTickClock.new()
	grid = CollisionGrid.new(cell_size_mm)
	actors = ActorRegistry.new()
	player_id = actors.spawn_actor(start_position, player_radius_mm)
	actors.get_actor(player_id).hit_points = player_hit_points
	_event_bus = event_bus
	_weapons[player_id] = Weapon.cz75()
	_focus = FocusState.new()
	_ground = GroundState.new()


## Spawns an AI-controlled Actor with its own AiAgent (Pass 5) and a
## default weapon (Pass 6's Weapon.cz75() for every archetype — real
## per-archetype loadouts are content-authoring data this pass has none
## of yet, tracked the same way Pass 6 deferred the Škorpion's suspicion
## consequence). Returns the new actor's ID.
func spawn_ai(
	position: Vector2i,
	radius_mm: int,
	archetype: AiArchetype,
	facing_dir: Vector2i = Vector2i(1, 0),
	hit_points: int = DEFAULT_AI_HIT_POINTS
) -> int:
	var id: int = actors.spawn_actor(position, radius_mm)
	var actor: Actor = actors.get_actor(id)
	actor.hit_points = hit_points
	actor.facing_dir = facing_dir
	_ai_agents[id] = AiAgent.new(id, archetype, facing_dir)
	_weapons[id] = Weapon.cz75()
	return id


## Advances the sim by exactly one tick, applying one InputFrame: the
## Ground verb's hold-duration gate (§4.6), then — only if Ground isn't
## being requested this tick — player movement and combat verbs, then
## every AI actor's perception and (v0) reaction regardless. A tick's
## noise events (sprint, gunfire, a landed throw) are collected as they
## happen and offered to every AI actor's hearing check the same tick
## they occur — same-tick reaction is a v0 simplification; real audio
## propagation delay is a presentation-layer concern with nothing to
## attach to before a real level exists. The same list is kept for
## capture_percept_snapshot() (Pass 9's "sound_events") — each entry
## also carries a "tag" and "source_id" the AI hearing check never
## needed, added for percept's benefit (AudioSwap/PhantomAudio, §4.2).
func step(frame: InputFrame) -> void:
	clock.advance()
	var ground_requested: bool = bool(frame.inputs.get("ground", false))
	_ground.advance_tick(ground_requested)

	var noise_events: Array = []
	if not ground_requested:
		_resolve_player_movement(frame, noise_events)
		_resolve_player_combat(frame, noise_events)
	_resolve_ai_ticks(noise_events)
	_last_tick_sound_events = noise_events

	if _ground.just_completed():
		_resolve_ground_completion()


## Reads "move_x"/"move_y" as a raw per-tick millimeter delta request —
## turning player intent (a direction, a speed) into that delta is
## MovementProfile.resolve_delta()'s job (Pass 6), called by whatever
## future input layer builds the InputFrame; TruthSim only ever sees
## "move by this many mm, resolved against collision." The optional
## "sprinting" flag is independent of that delta and exists purely to
## classify this tick's movement noise (MovementProfile.noise_loudness()),
## since a delta alone can't say which movement mode produced it.
func _resolve_player_movement(frame: InputFrame, noise_events: Array) -> void:
	var dx: int = int(frame.inputs.get("move_x", 0))
	var dy: int = int(frame.inputs.get("move_y", 0))
	var delta := Vector2i(dx, dy)
	if delta == Vector2i.ZERO:
		return

	var actor: Actor = actors.get_actor(player_id)
	var new_pos: Vector2i = SweptCollision.move_with_collision(
		actor.position, actor.radius_mm, delta, grid
	)
	if new_pos == actor.position:
		return
	actor.position = new_pos
	if _event_bus:
		_event_bus.publish(
			"ActorMoved", {"id": player_id, "position": new_pos}, null, clock.current_tick
		)
	if bool(frame.inputs.get("sprinting", false)):
		(
			noise_events
			. append(
				{
					"position": new_pos,
					"loudness": MovementProfile.SPRINT_NOISE_LOUDNESS,
					"tag": "footsteps",
					"source_id": player_id,
				}
			)
		)


## Resolves the player's aim/fire/reload/takedown/throw/focus verbs
## (Pass 6's standalone modules, wired in for real here). Every key is
## optional — an InputFrame with none of them is exactly Pass 3's
## movement-only contract.
func _resolve_player_combat(frame: InputFrame, noise_events: Array) -> void:
	var player: Actor = actors.get_actor(player_id)
	var weapon: Weapon = _weapons[player_id]

	if bool(frame.inputs.get("reload", false)):
		weapon.start_reload()

	if bool(frame.inputs.get("fire", false)):
		var aim_dir: Vector2i = frame.inputs.get("aim_dir", Vector2i.ZERO)
		if aim_dir != Vector2i.ZERO and weapon.can_fire():
			var targets: Array = _living_targets_other_than(player_id)
			var hit_id: int = CombatResolver.resolve_fire(
				player.position, aim_dir, weapon, targets, grid
			)
			weapon.fire()
			(
				noise_events
				. append(
					{
						"position": player.position,
						"loudness": weapon.fire_noise_loudness,
						"tag": "gunshot",
						"source_id": player_id,
					}
				)
			)
			if _event_bus:
				_event_bus.publish(
					"WeaponFired",
					{"shooter_id": player_id, "hit_id": hit_id},
					null,
					clock.current_tick
				)
			if hit_id != -1:
				_apply_hit(hit_id)

	var takedown_target_id: int = int(frame.inputs.get("takedown_target_id", -1))
	if takedown_target_id != -1 and actors.has_actor(takedown_target_id):
		var target: Actor = actors.get_actor(takedown_target_id)
		if (
			target.is_alive()
			and CombatResolver.resolve_takedown(player.position, target.position, grid)
		):
			if _event_bus:
				_event_bus.publish(
					"TakedownPerformed",
					{"actor_id": player_id, "target_id": takedown_target_id},
					null,
					clock.current_tick
				)
			_apply_hit(takedown_target_id, target.hit_points)  # instant kill

	var throw_target: Variant = frame.inputs.get("throw_target", null)
	if throw_target != null:
		var result: Dictionary = CombatResolver.resolve_throw(player.position, throw_target)
		if result.get("landed", false):
			(
				noise_events
				. append(
					{
						"position": result["position"],
						"loudness": result["noise_loudness"],
						"tag": "thrown_object",
						"source_id": player_id,
					}
				)
			)
			if _event_bus:
				_event_bus.publish(
					"ThrowLanded", {"position": result["position"]}, null, clock.current_tick
				)

	if bool(frame.inputs.get("focus", false)):
		_focus.activate()
	_focus.advance_tick()
	weapon.advance_tick()


## Every AI actor perceives the player (Pass 5's VisionCone/LineOfSight
## via AiAgent) and, v0-scoped, acts only on ENGAGE by firing back —
## PATROL/INVESTIGATE/FLEE/REPORT have no movement or radio consequence
## yet (a real patrol route needs authored waypoint data, and REPORT's
## backup-calling needs other AI to call in; neither exists before a real
## content pipeline, Pass 13+). This is still a real fight: an AI that
## spots the player can kill them, and vice versa.
func _resolve_ai_ticks(noise_events: Array) -> void:
	var player: Actor = actors.get_actor(player_id)
	for id: int in actors.all_ids():
		if id == player_id or not _ai_agents.has(id):
			continue
		var ai_actor: Actor = actors.get_actor(id)
		if not ai_actor.is_alive():
			continue

		var heard_noise: bool = false
		for evt: Dictionary in noise_events:
			if CombatResolver.is_noise_heard_at(
				evt["position"], ai_actor.position, evt["loudness"]
			):
				heard_noise = true
				break

		var agent: AiAgent = _ai_agents[id]
		var state: AiUtility.State = agent.perceive_and_decide(
			ai_actor.position, player.position, grid, heard_noise
		)

		var weapon: Weapon = _weapons[id]
		if state == AiUtility.State.ENGAGE and player.is_alive() and weapon.can_fire():
			var aim_dir: Vector2i = _clamped_aim_dir(ai_actor.position, player.position)
			var targets: Array = [{"id": player_id, "position": player.position}]
			var hit_id: int = CombatResolver.resolve_fire(
				ai_actor.position, aim_dir, weapon, targets, grid
			)
			weapon.fire()
			if _event_bus:
				_event_bus.publish(
					"WeaponFired", {"shooter_id": id, "hit_id": hit_id}, null, clock.current_tick
				)
			if hit_id == player_id:
				_apply_hit(player_id)
		weapon.advance_tick()


## master_plan §4.6: Ground "resolves all active ops in scope
## simultaneously" — that half is percept's job, via PerceptRenderer
## reading "ground_just_completed" off this tick's snapshot (see
## capture_percept_snapshot()'s class doc). On the truth side, this
## checks whether the moment was observed: "if observed by an Argus NPC
## in a social scene, a suspicion entry (weight 2)." No social-NPC system
## exists yet (Pass 16+), so "observed" is checked the same way Pass 7's
## AI perception already works — a fresh VisionCone+LineOfSight query
## against whichever actors can currently see the player, deliberately
## not routed through AiAgent.perceive_and_decide() so checking "was I
## seen while grounding" never mutates an agent's own memory/decision
## state as a side effect. Published as stub events for a future
## SuspicionGraph to consume — "state now, consumer later," the same
## pattern as every prior pass's own deferred wiring. "On empty" (§4.6:
## grounding when nothing is distorted "still tells you something true")
## falls out for free: GroundCompleted always publishes on completion,
## regardless of whether anything was actually active to resolve.
func _resolve_ground_completion() -> void:
	var player: Actor = actors.get_actor(player_id)
	var observed_by: int = -1
	for id: int in actors.all_ids():
		if id == player_id or not _ai_agents.has(id):
			continue
		var ai_actor: Actor = actors.get_actor(id)
		if not ai_actor.is_alive():
			continue
		var agent: AiAgent = _ai_agents[id]
		var can_see: bool = (
			VisionCone.point_in_cone(
				ai_actor.position,
				agent.facing_dir,
				agent.archetype.vision_cos_sq_half_angle_fx,
				agent.archetype.vision_range_mm,
				player.position
			)
			and LineOfSight.has_clear_line(ai_actor.position, player.position, grid)
		)
		if can_see:
			observed_by = id
			break

	if not _event_bus:
		return
	_event_bus.publish("GroundCompleted", {"observed_by": observed_by}, null, clock.current_tick)
	if observed_by != -1:
		_event_bus.publish(
			"GroundObserved",
			{"observer_id": observed_by, "suspicion_weight": GROUND_OBSERVED_SUSPICION_WEIGHT},
			null,
			clock.current_tick
		)


func _apply_hit(target_id: int, damage: int = HIT_DAMAGE) -> void:
	var target: Actor = actors.get_actor(target_id)
	target.apply_damage(damage)
	if not target.is_alive() and _event_bus:
		_event_bus.publish("ActorDowned", {"id": target_id}, null, clock.current_tick)


func _living_targets_other_than(exclude_id: int) -> Array:
	var targets: Array = []
	for id: int in actors.all_ids():
		if id == exclude_id:
			continue
		var a: Actor = actors.get_actor(id)
		if a.is_alive():
			targets.append({"id": id, "position": a.position})
	return targets


## Clamps a raw displacement to VisionCone's FACING_COMPONENT_MAX so an AI
## firing at a player many meters away never overflows point_in_cone()'s
## assert — this only ever changes the aim vector's magnitude, and the
## clamp is per-component (not a true normalize, which would need the
## sqrt this codebase avoids in sim code), so the direction can skew
## slightly for far-off, off-axis targets. Acceptable for a "does the AI
## shoot roughly at the player" v0 check; exact ballistics tuning is a
## Pass 7 graybox-playtest question like everything else in §4.9's
## checklist.
func _clamped_aim_dir(from_pos: Vector2i, to_pos: Vector2i) -> Vector2i:
	var d: Vector2i = to_pos - from_pos
	return Vector2i(
		clampi(d.x, -VisionCone.FACING_COMPONENT_MAX, VisionCone.FACING_COMPONENT_MAX),
		clampi(d.y, -VisionCone.FACING_COMPONENT_MAX, VisionCone.FACING_COMPONENT_MAX)
	)


func run_replay(replay: ReplayLog) -> void:
	for frame: InputFrame in replay.frames:
		step(frame)


func player_position() -> Vector2i:
	return actors.get_actor(player_id).position


## Read-only introspection for tests (and, later, an AI-state debug HUD):
## _ai_agents/_focus are private sim-internal wiring, not something
## callers should reach into directly.
func ai_current_state(ai_id: int) -> AiUtility.State:
	var agent: AiAgent = _ai_agents[ai_id]
	return agent.current_state


func is_focus_active() -> bool:
	return _focus.is_active()


func focus_activation_count() -> int:
	return _focus.activation_count


func is_grounding() -> bool:
	return _ground.is_holding()


func ground_use_count() -> int:
	return _ground.use_count


func player_weapon_ammo() -> int:
	var weapon: Weapon = _weapons[player_id]
	return weapon.ammo_in_magazine


func player_weapon_is_reloading() -> bool:
	var weapon: Weapon = _weapons[player_id]
	return weapon.is_reloading()


## Exports a read-only snapshot of truth state for the percept layer
## (master_plan.md §5.2: "percept state (read-only views)"). Every field
## is a plain value (int/bool/Vector2i) copied out of each Actor, never a
## reference to the Actor itself — mutating the returned Dictionary
## cannot reach back into this TruthSim's real state, which is what
## actually makes "read-only" true rather than a naming convention.
## `src/percept/`'s own code never references TruthSim/Actor by name at
## all (enforced by tools/percept_truth_boundary_lint.py in CI) — this
## method is the one, deliberate seam where truth hands data upward,
## exactly as the architecture diagram's single arrow describes.
##
## "sound_events" (Pass 9) is this same tick's noise events (sprint,
## gunfire, a landed throw — see step()'s class doc), the real truth
## source AudioSwap/PhantomAudio (master_plan §4.2) operate on.
##
## "ground_just_completed" (Pass 10) is the signal PerceptRenderer reads
## to call resolve_grounded() instead of apply() on every active op this
## tick (§4.6: "resolves all active ops in scope simultaneously").
func capture_percept_snapshot() -> Dictionary:
	var actor_snapshots: Array = []
	for id: int in actors.all_ids():
		var a: Actor = actors.get_actor(id)
		(
			actor_snapshots
			. append(
				{
					"id": a.id,
					"position": a.position,
					"facing_dir": a.facing_dir,
					"radius_mm": a.radius_mm,
					"hit_points": a.hit_points,
					"is_alive": a.is_alive(),
				}
			)
		)
	return {
		"tick": clock.current_tick,
		"player_id": player_id,
		"actors": actor_snapshots,
		"sound_events": _last_tick_sound_events.duplicate(true),
		"ground_just_completed": _ground.just_completed(),
		"ground_is_holding": _ground.is_holding(),
	}
