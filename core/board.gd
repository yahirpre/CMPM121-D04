## The ground the dragon moves over: one tile kind per cell (Type Object).
## Rules ask what a kind means, never which kind it is, so a new kind is a new
## row in TILES plus a piece of the same name in tools/build_art.py.
class_name Board
extends RefCounted

## What each tile kind means to the rules.
const TILES := {
	"floor": {"solid": false},
	"wall": {"solid": true},
}

var size: Vector2i
var tiles := {}  # Vector2i cell -> tile kind name


## A floor ringed by walls: the default until you load levels from text files.
static func bordered(grid_size: Vector2i) -> Board:
	var board := Board.new()
	board.size = grid_size
	for x in grid_size.x:
		for y in grid_size.y:
			var edge := x == 0 or y == 0 or x == grid_size.x - 1 or y == grid_size.y - 1
			board.tiles[Vector2i(x, y)] = "wall" if edge else "floor"
	return board


func kind_at(cell: Vector2i) -> String:
	return tiles.get(cell, "wall")  # off the board counts as wall


func is_solid(cell: Vector2i) -> bool:
	return TILES[kind_at(cell)].solid
