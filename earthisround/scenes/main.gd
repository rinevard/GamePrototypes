extends MetSysGame

func _ready():
	MetSys.reset_state()
	MetSys.set_save_data()
	set_player($Player)
	load_room("res://scenes/maps/left_room.tscn")
	# Add module for room transitions.
	add_module("RoomTransitions.gd")

func _process(delta):
	var possilble_edge: Node2D = MetSys.get_current_room_instance().get_parent()
	if possilble_edge.has_signal("world_edge_entered"):
		if not possilble_edge.is_connected("world_edge_entered", _on_enter_worldedge):
			print(MetSys.get_current_room_instance().get_parent().name)
			possilble_edge.world_edge_entered.connect(_on_enter_worldedge)

func _on_enter_worldedge(change_level: String):
	print(MetSys.get_current_room_instance().get_parent().name)
	load_room(change_level)
