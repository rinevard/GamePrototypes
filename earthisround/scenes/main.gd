extends MetSysGame

func _ready():
	MetSys.reset_state()
	MetSys.set_save_data()
	set_player($Player)
	add_module("RoomTransitions.gd")
	room_loaded.connect(_on_room_loaded)
	load_room("res://scenes/maps/left_room.tscn")
	# Add module for room transitions.
	player.need_clear_range.connect(_clear_range)

func _clear_range(range_to_clear: Array[Vector2]):
	MetSys.get_current_room_instance().get_parent().remove_tiles(range_to_clear)

func _on_enter_worldedge(change_level: String):
	print(MetSys.get_current_room_instance().get_parent().name)
	load_room(change_level)
	
func _on_room_loaded():
	MetSys.get_current_room_instance().adjust_camera_limits($Player/Camera2D)
	var possilble_edge: Node2D = MetSys.get_current_room_instance().get_parent()
	if possilble_edge.has_signal("world_edge_entered"):
		if not possilble_edge.is_connected("world_edge_entered", _on_enter_worldedge):
			print(MetSys.get_current_room_instance().get_parent().name)
			possilble_edge.world_edge_entered.connect(_on_enter_worldedge)
