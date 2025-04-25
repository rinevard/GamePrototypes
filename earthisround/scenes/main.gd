extends MetSysGame

func _ready():
	MetSys.reset_state()
	MetSys.set_save_data()
	set_player($Player)
	load_room("res://scenes/maps/left_room.tscn")

	# Add module for room transitions.
	add_module("RoomTransitions.gd")
func _on_room_changed(new_room: String):
	print("change room")
