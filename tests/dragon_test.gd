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


func test_delay_is_actually_counted() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))
	dragon.count_delay()
	assert_eq(dragon.move_delay_current, 1)

	dragon.count_delay()
	assert_eq(dragon.move_delay_current, 2)

	dragon.count_delay(dragon.move_delay_max - dragon.move_delay_current)
	assert_true(dragon.move_delay_current >= dragon.move_delay_max)

	dragon.count_delay()
	assert_eq(dragon.move_delay_current, 0)


func test_delay_affects_movement() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))
	dragon.move_delay_max = 3
	for i in 3:
		dragon.tick()
		assert_eq(dragon.body[0], Vector2i(10, 10))

	dragon.tick()
	assert_true(dragon.body[0] != Vector2i(10, 10))


func test_speed_up_after_eating() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))
	var init_delay = dragon.move_delay_max
	dragon.grow(1)
	assert_eq(dragon.move_delay_max, init_delay - 1)

	dragon.grow(2)
	assert_eq(dragon.move_delay_max, init_delay - 3)


func test_growing_resets_move_delay_progress() -> void:
	var dragon := Dragon.new(Vector2i(10, 10))
	dragon.count_delay()
	dragon.count_delay()
	assert_eq(dragon.move_delay_current, 2)

	dragon.grow(1)
	assert_eq(dragon.move_delay_current, 0)
