extends "res://tests/test_case.gd"

var board := Board.bordered(Vector2i(6, 4))


func test_border_is_solid() -> void:
	assert_true(board.is_solid(Vector2i(0, 2)))
	assert_true(board.is_solid(Vector2i(5, 3)))


func test_inside_is_open() -> void:
	assert_eq(board.kind_at(Vector2i(2, 2)), "floor")
	assert_true(not board.is_solid(Vector2i(2, 2)))


func test_off_the_board_counts_as_wall() -> void:
	assert_true(board.is_solid(Vector2i(-1, 9)))


func test_every_kind_has_rules() -> void:
	for cell in board.tiles:
		assert_true(board.tiles[cell] in Board.TILES)
