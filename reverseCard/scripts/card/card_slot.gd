extends Area2D

var occupied = false
var current_card = null
var grid_position = Vector2i(0, 0)

signal slot_clicked(slot)

func _ready():
	input_event.connect(_on_input_event)
	add_to_group("card_slot")
	collision_layer = 2 # 设置碰撞层为2，与卡牌中的射线检测一致

func set_grid_position(x: int, y: int):
	grid_position = Vector2i(x, y)

func place_card(card):
	if card == null:
		return false
		
	if not occupied:
		occupied = true
		current_card = card
		# 确保卡牌位于卡槽中心
		card.position = Vector2.ZERO
		card.global_position = global_position
		card.set_current_slot(self)
		return true
	return false

func remove_card():
	var temp = current_card
	occupied = false
	current_card = null
	if temp != null:
		# 清除卡牌对此卡槽的引用
		temp.current_slot = null
	return temp

func is_adjacent_to(other_slot: Area2D) -> bool:
	if other_slot == null or not other_slot is Area2D:
		return false
		
	var diff = grid_position - other_slot.grid_position
	var manhattan_distance = abs(diff.x) + abs(diff.y)
	return manhattan_distance == 1

func has_valid_card() -> bool:
	return occupied and current_card != null and is_instance_valid(current_card)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(self)
