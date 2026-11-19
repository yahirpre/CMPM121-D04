## Which dragon piece goes in each body cell, and how many quarter turns it needs.
## Directions are grid steps: Vector2i.UP is (0, -1), away from the camera.
class_name Kit
extends RefCounted

enum Piece { HEAD, STRAIGHT, TURN, TAIL }

## The sides each piece connects to, as modeled (unrotated) in tools/build_art.py.
const OPENINGS := {
	Piece.HEAD: [Vector2i.DOWN],  # neck behind the head
	Piece.STRAIGHT: [Vector2i.UP, Vector2i.DOWN],
	Piece.TURN: [Vector2i.DOWN, Vector2i.RIGHT],
	Piece.TAIL: [Vector2i.UP],  # joins the body ahead of it
}


## One quarter turn, matching a +90 degree rotation around Godot's Y axis.
static func quarter_turn(direction: Vector2i) -> Vector2i:
	return Vector2i(direction.y, -direction.x)


## The grid step from one cell to its neighbor, even across the wrap-around edge.
static func step(from: Vector2i, to: Vector2i) -> Vector2i:
	var d := to - from
	if abs(d.x) > 1:
		d.x = -signi(d.x)
	if abs(d.y) > 1:
		d.y = -signi(d.y)
	return d


## How many quarter turns make the piece's openings face the given sides.
static func quarter_turns(piece: Piece, sides: Array) -> int:
	var openings: Array = OPENINGS[piece]
	for turns in 4:
		if openings.size() == sides.size() and openings.all(func(o): return o in sides):
			return turns
		openings = openings.map(func(o): return quarter_turn(o))
	push_error("No rotation of %s connects %s" % [Piece.keys()[piece], sides])
	return 0


## [piece, quarter turns] for every cell of the body, head first.
static func layout(body: Array[Vector2i]) -> Array:
	var placed := []
	var last := body.size() - 1
	for i in body.size():
		var toward_head := step(body[i], body[i - 1]) if i > 0 else Vector2i.ZERO
		var toward_tail := step(body[i], body[i + 1]) if i < last else Vector2i.ZERO
		var piece := Piece.TURN
		var sides := [toward_head, toward_tail]
		if i == 0:
			piece = Piece.HEAD
			sides = [toward_tail]
		elif i == last:
			piece = Piece.TAIL
			sides = [toward_head]
		elif toward_head == -toward_tail:
			piece = Piece.STRAIGHT
		placed.append([piece, quarter_turns(piece, sides)])
	return placed
