class_name Level
extends Node2D

@export var left_level_cross_edge: String
@export var right_level_cross_edge: String
enum LEVELTYPE { NORMAL, LEFTMOST, RIGHTMOST }

@export var level_type: LEVELTYPE

signal world_edge_entered(change_level: String)
@onready var area_2d: Area2D = null

func _ready():
	if level_type != LEVELTYPE.NORMAL:
		area_2d = $Area2D
		area_2d.body_entered.connect(_on_world_dege_area_entered)
	MetSys.register_storable_object($TileMapLayer)
	load_tilemap()

func _on_world_dege_area_entered(_body: Node2D):
	match level_type:
		LEVELTYPE.NORMAL:
			return
		LEVELTYPE.LEFTMOST:
			world_edge_entered.emit(left_level_cross_edge)
		LEVELTYPE.RIGHTMOST:
			world_edge_entered.emit(right_level_cross_edge)
		_:
			return

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
func remove_tiles(range_to_clear: Array[Vector2]):
	print("remove")
	var right_down_point: Vector2 = Vector2(600, 360)
	var tile_size: int = 10
	
	
	for global_pos in range_to_clear:
		var grid_pos: Vector2i = tile_map_layer.local_to_map(tile_map_layer.to_local(global_pos))
		tile_map_layer.erase_cell(grid_pos)
	
	# 我们在这里测试建立pattern，这是为了后面的保存做准备
	var pattern: TileMapPattern = TileMapPattern.new()
	pattern.set_size(tile_map_layer.local_to_map(right_down_point))
	for global_x in range(0, right_down_point.x + 1, tile_size):
		for global_y in range(0, right_down_point.y + 1, tile_size):
			var grid_pos: Vector2i = tile_map_layer.local_to_map(tile_map_layer.to_local(Vector2(global_x, global_y)))
			pattern.set_cell(grid_pos, 
			tile_map_layer.get_cell_source_id(grid_pos), tile_map_layer.get_cell_atlas_coords(grid_pos), 0)
	var dir = DirAccess.open("user://")
	if !dir.dir_exists("tile_pattern"):
		dir.make_dir("tile_pattern")
	if level_type == LEVELTYPE.NORMAL:
		ResourceSaver.save(pattern, "user://tile_pattern/" + name + "_tile_pattern.tres")
	else:
		ResourceSaver.save(pattern, "user://tile_pattern/" + "edge" + "_tile_pattern.tres")

func load_tilemap():
	var pathname = "user://tile_pattern/" + name + "_tile_pattern.tres" if level_type == LEVELTYPE.NORMAL else "user://tile_pattern/" + "edge" + "_tile_pattern.tres"
	if FileAccess.file_exists(pathname):
		var pattern = ResourceLoader.load(pathname) as TileMapPattern
		tile_map_layer.set_pattern(Vector2i.ZERO, pattern)
