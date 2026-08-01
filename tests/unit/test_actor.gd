extends AfterimageTestCase


func test_default_hit_points_and_facing() -> void:
	var actor := Actor.new(1, Vector2i(0, 0), 300)
	assert_eq(actor.hit_points, 1)
	assert_eq(actor.facing_dir, Vector2i(1, 0))
	assert_true(actor.is_alive())


func test_constructor_accepts_explicit_hit_points_and_facing() -> void:
	var actor := Actor.new(1, Vector2i(0, 0), 300, 3, Vector2i(0, -1))
	assert_eq(actor.hit_points, 3)
	assert_eq(actor.facing_dir, Vector2i(0, -1))


func test_apply_damage_reduces_hit_points() -> void:
	var actor := Actor.new(1, Vector2i(0, 0), 300, 3)
	actor.apply_damage(1)
	assert_eq(actor.hit_points, 2)
	assert_true(actor.is_alive())


func test_apply_damage_down_to_zero_is_not_alive() -> void:
	var actor := Actor.new(1, Vector2i(0, 0), 300, 2)
	actor.apply_damage(2)
	assert_eq(actor.hit_points, 0)
	assert_false(actor.is_alive())


func test_apply_damage_clamps_at_zero_rather_than_going_negative() -> void:
	var actor := Actor.new(1, Vector2i(0, 0), 300, 2)
	actor.apply_damage(50)
	assert_eq(actor.hit_points, 0)
	assert_false(actor.is_alive())
