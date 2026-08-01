## The recorded stream of InputFrames + seed + content version that IS a
## mission-in-progress save and IS the Afterimage Theater's source
## (tech_guidelines.md §3.1, §5.3; foundation_blueprints.md §6). Re-running
## a TruthSim (Pass 3+) over a ReplayLog must reproduce the exact same
## tick-by-tick state — that guarantee is what a "replay" means here.
##
## `replay_version` is tracked separately from the save schema_version
## (foundation_blueprints.md §6): a replay declares what engine/content it
## needs to re-simulate truthfully, and refuses to load rather than
## replaying something it can't guarantee matches.
class_name ReplayLog
extends RefCounted

const REPLAY_VERSION: int = 1

var run_seed: int = 0
var content_version: String = ""
var frames: Array[InputFrame] = []


func _init(p_run_seed: int = 0, p_content_version: String = "") -> void:
	run_seed = p_run_seed
	content_version = p_content_version


func record(frame: InputFrame) -> void:
	frames.append(frame)


func frame_count() -> int:
	return frames.size()


func to_dict() -> Dictionary:
	var frame_dicts: Array = []
	for f: InputFrame in frames:
		frame_dicts.append(f.to_dict())
	return {
		"replay_version": REPLAY_VERSION,
		"run_seed": run_seed,
		"content_version": content_version,
		"frames": frame_dicts,
	}


## Fails loudly (assert) on an unsupported replay_version rather than
## silently attempting to replay data this build cannot guarantee it
## understands — a wrong replay is worse than a refused one.
static func from_dict(d: Dictionary) -> ReplayLog:
	var version: int = int(d.get("replay_version", -1))
	assert(
		version == REPLAY_VERSION,
		(
			"ReplayLog: unsupported replay_version %d (this build supports %d)"
			% [version, REPLAY_VERSION]
		)
	)
	var log := ReplayLog.new(int(d.get("run_seed", 0)), String(d.get("content_version", "")))
	for fd: Dictionary in d.get("frames", []):
		log.frames.append(InputFrame.from_dict(fd))
	return log
