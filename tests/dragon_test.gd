extends "res://tests/test_case.gd"


func test_moves_one_cell_per_tick() -> void:
	var dragon := Dragon.new(Vector2i(10, 10), 3)
	dragon.tick()
	assert_eq(dragon.body, [Vector2i(6, 5), Vector2i(5, 5), Vector2i(4, 5)])


func test_reversing_into_the_neck_is_ignored() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))
	dragon.turn(Vector2i.LEFT)
	dragon.tick()
	assert_eq(dragon.heading, Vector2i.RIGHT)


func test_two_quick_turns_apply_on_successive_ticks() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))
	dragon.turn(Vector2i.UP)
	dragon.turn(Vector2i.LEFT)
	dragon.tick()
	assert_eq(dragon.heading, Vector2i.UP)
	dragon.tick()
	assert_eq(dragon.heading, Vector2i.LEFT)


func test_wraps_at_the_edge() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))
	for i in 5:
		dragon.tick()
	assert_eq(dragon.body[0], Vector2i(0, 5))
