## A firearm's ammo/reload state machine (master_plan.md §4.9's weapons
## list). Reload is tick-counted, not a wall-clock timer — every duration
## in this sim is authored directly in ticks or converted to ticks once at
## load (tech_guidelines §3.1), never accumulated from per-frame delta
## time, so a replay's reload finishes on the exact same tick no matter
## what machine replays it or how fast that machine renders.
class_name Weapon
extends RefCounted

var magazine_capacity: int
var ammo_in_magazine: int
var reload_ticks: int
var fire_noise_loudness: int
var max_range_mm: int
var lethal: bool

var _reload_ticks_remaining: int = 0


func _init(
	p_magazine_capacity: int,
	p_reload_ticks: int,
	p_fire_noise_loudness: int,
	p_max_range_mm: int,
	p_lethal: bool = true
) -> void:
	magazine_capacity = p_magazine_capacity
	ammo_in_magazine = p_magazine_capacity
	reload_ticks = p_reload_ticks
	fire_noise_loudness = p_fire_noise_loudness
	max_range_mm = p_max_range_mm
	lethal = p_lethal


## Loud, reliable sidearm. The Argus-issue Škorpion vz. 61 master_plan
## §4.9 also lists is deliberately omitted here: carrying it is itself a
## suspicion entry regardless of cover (§4.7), which is day-phase/social-
## stealth data this pass has no model for yet — adding its stats without
## that consequence wired up would misrepresent it. Revisit alongside
## §4.7's suspicion system.
static func cz75() -> Weapon:
	return Weapon.new(12, 60, 90, 12000, true)


## Quiet, weaker sidearm (suppressed .32).
static func suppressed_32() -> Weapon:
	return Weapon.new(8, 75, 20, 9000, true)


func is_reloading() -> bool:
	return _reload_ticks_remaining > 0


func can_fire() -> bool:
	return ammo_in_magazine > 0 and not is_reloading()


func start_reload() -> void:
	if is_reloading() or ammo_in_magazine == magazine_capacity:
		return
	_reload_ticks_remaining = reload_ticks


## Consumes one round. Returns false (state untouched) if can_fire() would
## have been false — callers who need to know *why* a fire attempt failed
## check can_fire() themselves; this is only the mutating half.
func fire() -> bool:
	if not can_fire():
		return false
	ammo_in_magazine -= 1
	return true


## Advances the reload countdown by one tick; refills the magazine on the
## exact tick it completes. A no-op when not reloading, so callers can
## call this unconditionally once per TruthSim tick.
func advance_tick() -> void:
	if _reload_ticks_remaining <= 0:
		return
	_reload_ticks_remaining -= 1
	if _reload_ticks_remaining == 0:
		ammo_in_magazine = magazine_capacity
