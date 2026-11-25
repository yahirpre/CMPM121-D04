## One run at the game: the board and the dragon on it, from the first tick until the
## run ends. Rules that involve more than the dragon (food, score, what the dragon can
## run into) belong here, so Dragon stays about movement and app/ only draws.
class_name Session
extends RefCounted

var board: Board
var dragon: Dragon
var fish: Vector2i
var grid: Vector2i
var rng_seed: int = 1
var rng := RandomNumberGenerator.new()



var state: Dictionary = {"score": 0, "result": 0} # result: -1 is loss, result: 1 is win, result: 0 is in-play

func _init(grid_size: Vector2i) -> void:
	board = Board.bordered(grid_size)
	dragon = Dragon.new(grid_size)
	grid = grid_size
	rng.seed = rng_seed
	spawn_fish(grid)

## One step of the rules. TODO for D4: food, growth, and collisions with the dragon's
## own body and with solid tiles (board.is_solid). Each needs the dragon and something
## else, which is why they go here rather than in Dragon.tick.
func tick() -> bool:
	dragon.tick()
	checkCrash(dragon.body[0])
	checkEat(dragon.body[0])

	return (not state.result)


func checkCrash(cell: Vector2i):
	if (board.is_solid(cell) == true): 
		lose()


func lose():
	print("Lose");
	state.result = -1


func win():
	print("Win");
	state.result = 1


func is_fish(position: Vector2i):
	return fish == position

func checkEat(cell: Vector2i):
	if (is_fish(cell)):
		dragon.grow(1)
		state.score += 1

		# change fish position
		spawn_fish(grid)

func spawn_fish(grid_size):
	fish = Vector2i(rng.randi_range(0, grid_size.x), rng.randi_range(0,grid_size.y))