## A deliberately tiny, disposable stand-in for TruthSim (Pass 3+),
## existing only to exercise and prove the determinism-corpus mechanism —
## recording, replay, hashing, divergence-detection — before a real
## simulation exists to run it against. Delete this file once TruthSim
## lands and point the corpus tests at that instead.
##
## Not shipped: lives under tests/fixtures/, not src/, precisely because it
## is not part of the game (mirrors MockWorldQuery living in
## tests/framework/ rather than src/core/).
class_name StubSim
extends RefCounted


## Runs a deterministic toy simulation over a replay's frames and returns a
## SHA-256 hex digest of the final state. The one property that matters:
## two calls given equal ReplayLogs must always return equal digests —
## that equality *is* what "deterministic replay" means for the mechanism
## this stands in for (tech_guidelines.md §3, §9).
static func run_and_digest(replay: ReplayLog) -> String:
	var rng := Xoshiro128StarStar.new(replay.run_seed)
	var pos_x: int = 0
	var pos_y: int = 0
	var accumulator: int = FixedMath.ZERO
	var roll_total: int = 0

	for frame: InputFrame in replay.frames:
		var dx: int = int(frame.inputs.get("move_x", 0))
		var dy: int = int(frame.inputs.get("move_y", 0))
		pos_x += dx
		pos_y += dy
		var step: int = FixedMath.from_int(dx + dy)
		accumulator = FixedMath.mul(accumulator + step, FixedMath.from_float(1.05))
		if bool(frame.inputs.get("roll", false)):
			roll_total += rng.next_range_int(1, 6)

	var state_text: String = (
		"frames=%d;seed=%d;content=%s;pos=(%d,%d);accum=%d;rolls=%d"
		% [
			replay.frames.size(),
			replay.run_seed,
			replay.content_version,
			pos_x,
			pos_y,
			accumulator,
			roll_total,
		]
	)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(state_text.to_utf8_buffer())
	return ctx.finish().hex_encode()
