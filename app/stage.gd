## The world around the dragon: sky, sun, and the board's tiles. Built once and never
## changed during play, so each kind of tile is one MultiMesh (Flyweight made visible:
## one mesh uploaded once, drawn at a thousand transforms in one call).
class_name Stage
extends Node3D

const SKY_TOP := Color("1b2f4a")
const HORIZON := Color("e0936a")  # dusk; the fog uses it too, so the floor melts into the sky
const EARTH := Color("3a2f2a")  # warm dark ground beyond the board

var rng := RandomNumberGenerator.new()  # seeded, so the stage looks the same every load


## art/dragon_kit.glb holds one object per piece: the dragon's head, straight, turn,
## and tail, plus one per tile kind in Board.TILES. Returns piece name -> Mesh. Only
## the meshes matter: where build_art.py placed each object (spread out, so the .glb
## previews well in a model viewer) is ignored.
static func load_kit() -> Dictionary:
	var meshes := {}
	var kit: Node = load("res://art/dragon_kit.glb").instantiate()
	for child in kit.find_children("*", "MeshInstance3D"):
		meshes[String(child.name)] = child.mesh
		_use_vertex_colors(child.mesh)
	kit.free()
	return meshes


## glTF says vertex colors (COLOR_0) tint the base color, but Godot's importer only
## turns that on for some materials. If you bake shading into vertex colors in
## Blender, this makes sure it shows.
static func _use_vertex_colors(mesh: Mesh) -> void:
	for surface in mesh.get_surface_count():
		var material := mesh.surface_get_material(surface) as BaseMaterial3D
		if material and mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR] != null:
			material.vertex_color_use_as_albedo = true


## tiles maps each cell (Vector2i) to a kind name ("floor", "wall", ...); meshes maps
## kind names to the kit's meshes. A new kind needs a mesh, not new code here.
func _init(tiles: Dictionary, meshes: Dictionary) -> void:
	rng.seed = 121
	add_child(_world())
	add_child(_sun())
	var cells_of := {}  # kind -> the cells that hold it
	for cell in tiles:
		cells_of.get_or_add(tiles[cell], []).append(cell)
	for kind in cells_of:
		if kind in meshes:
			add_child(_scatter(meshes[kind], cells_of[kind]))
		else:
			push_warning("The kit has no piece named %s; add one and run deno task art" % kind)
	add_child(_skirt())


## Sky, ambient light, tonemapping, glow, ambient occlusion, and fog in one resource.
func _world() -> WorldEnvironment:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = HORIZON
	sky_material.ground_horizon_color = HORIZON
	sky_material.ground_bottom_color = EARTH
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY  # cool from above
	environment.ambient_light_energy = 0.5
	# AgX keeps hues as they brighten, so embers stay orange instead of going yellow-white.
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.tonemap_agx_contrast = 1.3
	# The web renderer's color buffer tops out near 1.0, so the glow threshold sits
	# just below that: only emissive materials (eyes, embers) bleed light.
	environment.glow_enabled = true
	environment.glow_hdr_threshold = 0.85
	environment.glow_intensity = 0.9
	environment.glow_bloom = 0.03
	environment.adjustment_enabled = true  # AgX mutes greens a little; win them back
	environment.adjustment_saturation = 1.2
	environment.ssao_enabled = true  # dark creases where the dragon meets the floor
	# Depth fog fades the far floor to the horizon color, hiding the edge of the world.
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = HORIZON.darkened(0.2)
	environment.fog_depth_begin = 22.0
	environment.fog_depth_end = 70.0
	environment.fog_sky_affect = 0.0
	var world := WorldEnvironment.new()
	world.environment = environment
	return world


## A low warm sun: long soft shadows read as "late afternoon" and show the shapes.
func _sun() -> DirectionalLight3D:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 35, 0)
	sun.light_color = Color("ffd2a1")
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 60.0
	return sun


## Ground beyond the board, just under the tiles, so the board is not floating in the sky.
func _skirt() -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = EARTH
	material.roughness = 1.0
	var plane := PlaneMesh.new()
	plane.size = Vector2(400, 400)
	plane.material = material
	var skirt := MeshInstance3D.new()
	skirt.mesh = plane
	skirt.position.y = -0.3
	return skirt


## One MultiMesh draws a copy of mesh in every cell, placed exactly as the kit modeled it.
func _scatter(mesh: Mesh, cells: Array) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true  # must be set before instance_count
	multimesh.mesh = _tintable(mesh)
	multimesh.instance_count = cells.size()
	for i in cells.size():
		var cell: Vector2i = cells[i]
		# Quarter turns and slight shade changes keep a thousand copies from looking stamped.
		var turn := Basis(Vector3.UP, rng.randi_range(0, 3) * PI / 2)
		multimesh.set_instance_transform(
			i, Transform3D(turn, Vector3(cell.x + 0.5, 0, cell.y + 0.5))
		)
		var shade := (1.0 if (cell.x + cell.y) % 2 == 0 else 0.92) * rng.randf_range(0.95, 1.04)
		multimesh.set_instance_color(i, Color(shade, shade, shade))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	return instance


## Instance colors only show when the material multiplies albedo by vertex color, so
## we copy the kit's mesh and switch that on (the shared kit mesh stays untouched).
func _tintable(mesh: Mesh) -> Mesh:
	var copy: Mesh = mesh.duplicate()
	for surface in copy.get_surface_count():
		var material := copy.surface_get_material(surface)
		if material is BaseMaterial3D and not material.vertex_color_use_as_albedo:
			material = material.duplicate()
			material.vertex_color_use_as_albedo = true
			copy.surface_set_material(surface, material)
	return copy
