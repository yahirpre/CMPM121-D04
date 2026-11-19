extends "res://tests/test_case.gd"


func test_head_faces_heading() -> void:
	var body: Array[Vector2i] = [Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5)]
	var placed := Kit.layout(body)
	assert_eq(placed[0], [Kit.Piece.HEAD, 3])  # facing right is -90 degrees
	assert_eq(placed[1], [Kit.Piece.STRAIGHT, 1])
	assert_eq(placed[2], [Kit.Piece.TAIL, 3])


func test_corner_gets_the_turn_piece() -> void:
	# Heading up after moving right: the middle cell joins its left and top sides.
	var body: Array[Vector2i] = [Vector2i(5, 4), Vector2i(5, 5), Vector2i(4, 5)]
	var placed := Kit.layout(body)
	assert_eq(placed[1][0], Kit.Piece.TURN)
	var sides := Kit.OPENINGS[Kit.Piece.TURN].map(
		func(o):
			for i in placed[1][1]:
				o = Kit.quarter_turn(o)
			return o
	)
	assert_true(Vector2i.UP in sides and Vector2i.LEFT in sides)


func test_neighbors_across_the_wrap_are_adjacent() -> void:
	assert_eq(Kit.step(Vector2i(9, 3), Vector2i(0, 3)), Vector2i.RIGHT)
