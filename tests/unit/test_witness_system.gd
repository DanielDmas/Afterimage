extends AfterimageTestCase

const COS_SQ_45: int = 32768  # 0.5 * 65536, exact (see test_vision_cone.gd)


func _candidate(id: int, position: Vector2i, facing: Vector2i, range_mm: int = 1000) -> Dictionary:
	return {
		"id": id,
		"position": position,
		"facing": facing,
		"range_mm": range_mm,
		"cos_sq_half_angle_fx": COS_SQ_45,
	}


func test_no_candidates_yields_no_witnesses_but_still_logs() -> void:
	var ws := WitnessSystem.new()
	var grid := CollisionGrid.new(500)
	var witnesses: Array = ws.record_event(1, "shot_fired", Vector2i(500, 0), [], grid)
	assert_eq(witnesses, [])
	assert_eq(ws.entry_count(), 1)
	assert_eq(ws.log()[0]["event_tag"], "shot_fired")


func test_candidate_who_can_see_the_event_is_a_witness() -> void:
	var ws := WitnessSystem.new()
	var grid := CollisionGrid.new(500)
	var candidates: Array = [_candidate(1, Vector2i(0, 0), Vector2i(100, 0))]
	var witnesses: Array = ws.record_event(1, "shot_fired", Vector2i(500, 0), candidates, grid)
	assert_eq(witnesses, [1])


func test_candidate_facing_away_is_not_a_witness() -> void:
	var ws := WitnessSystem.new()
	var grid := CollisionGrid.new(500)
	var candidates: Array = [_candidate(1, Vector2i(0, 0), Vector2i(-100, 0))]  # facing away
	var witnesses: Array = ws.record_event(1, "shot_fired", Vector2i(500, 0), candidates, grid)
	assert_eq(witnesses, [])


func test_candidate_out_of_range_is_not_a_witness() -> void:
	var ws := WitnessSystem.new()
	var grid := CollisionGrid.new(500)
	var candidates: Array = [_candidate(1, Vector2i(0, 0), Vector2i(100, 0), 100)]  # range too short
	var witnesses: Array = ws.record_event(1, "shot_fired", Vector2i(500, 0), candidates, grid)
	assert_eq(witnesses, [])


func test_candidate_blocked_by_a_wall_is_not_a_witness() -> void:
	var ws := WitnessSystem.new()
	var grid := CollisionGrid.new(500)
	grid.set_cell_blocked(Vector2i(2, 0), true)
	var candidates: Array = [_candidate(1, Vector2i(0, 250), Vector2i(100, 0))]
	var witnesses: Array = ws.record_event(1, "shot_fired", Vector2i(2000, 250), candidates, grid)
	assert_eq(witnesses, [])


func test_multiple_witnesses_are_returned_sorted() -> void:
	var ws := WitnessSystem.new()
	var grid := CollisionGrid.new(500)
	var candidates: Array = [
		_candidate(3, Vector2i(0, 0), Vector2i(100, 0)),
		_candidate(1, Vector2i(0, 0), Vector2i(100, 0)),
		_candidate(2, Vector2i(0, 0), Vector2i(-100, 0)),  # facing away, not a witness
	]
	var witnesses: Array = ws.record_event(1, "shot_fired", Vector2i(500, 0), candidates, grid)
	assert_eq(witnesses, [1, 3])


func test_multiple_events_accumulate_in_the_log() -> void:
	var ws := WitnessSystem.new()
	var grid := CollisionGrid.new(500)
	ws.record_event(1, "shot_fired", Vector2i(500, 0), [], grid)
	ws.record_event(2, "body_found", Vector2i(600, 0), [], grid)
	assert_eq(ws.entry_count(), 2)
	assert_eq(ws.log()[0]["tick"], 1)
	assert_eq(ws.log()[1]["tick"], 2)
	assert_eq(ws.log()[1]["event_tag"], "body_found")
