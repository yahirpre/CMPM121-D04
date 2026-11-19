## deno task kit: see the kit as the game will, under the game's own lighting.
## A sample dragon shows how the pieces join through turns; in front of the board,
## every piece in the kit stands in a row with its name.
extends Node3D

const SIZE := Vector2i(12, 9)
## A body, head first like Dragon.body, with turns both ways.
const SAMPLE: Array[Vector2i] = [
	Vector2i(8, 2),
	Vector2i(7, 2),
	Vector2i(6, 2),
	Vector2i(5, 2),
	Vector2i(5, 3),
	Vector2i(5, 4),
	Vector2i(4, 4),
	Vector2i(3, 4),
	Vector2i(3, 5),
	Vector2i(3, 6),
]

var meshes := {}
var camera := Camera3D.new()
var _angle := 0.0


func _ready() -> void:
	meshes = Stage.load_kit()
	add_child(Stage.new(Board.bordered(SIZE).tiles, meshes))
	var placed := Kit.layout(SAMPLE)
	for i in SAMPLE.size():
		var piece: String = Kit.Piece.keys()[placed[i][0]].to_lower()
		_show(piece, Vector3(SAMPLE[i].x + 0.5, 0, SAMPLE[i].y + 0.5), placed[i][1] * PI / 2)
	var names: Array = meshes.keys()
	names.sort()
	for i in names.size():
		var spot := Vector3(1.0 + i * 1.6, 0, SIZE.y + 1.5)
		_show(names[i], spot, 0.0)
		var label := Label3D.new()
		label.text = names[i]
		label.font_size = 64
		label.outline_size = 12
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = spot + Vector3(0, 0.1, 0.9)  # a caption just in front of its piece
		add_child(label)
	add_child(camera)


func _process(delta: float) -> void:
	_angle += delta * 0.2  # a slow orbit, so every side of every piece comes around
	var center := Vector3(SIZE.x / 2.0, 0, SIZE.y / 2.0 + 1.0)
	camera.position = center + Vector3(sin(_angle) * 8.5, 6.5, cos(_angle) * 8.5)
	camera.look_at(center)


func _show(piece: String, spot: Vector3, yaw: float) -> void:
	if piece not in meshes:
		push_warning("The kit has no piece named %s; run deno task art" % piece)
		return
	var node := MeshInstance3D.new()
	node.mesh = meshes[piece]
	node.position = spot
	node.rotation.y = yaw
	add_child(node)
