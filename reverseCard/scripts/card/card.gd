extends Area2D

enum CardType {FRIEND, ENEMY, EQUIPMENT}

var card_type: int
var health: int
var attack: int
var action_points: int
var max_action_points: int
var is_face_up: bool = false
var equipped_items = []
var flip_time: int = 0 # 记录翻牌时间

# 拖放相关变量
var dragging = false
var drag_offset = Vector2()
var original_position = Vector2()
var original_z_index = 0
var current_slot = null
var hovered_slot = null

signal card_clicked(card)
signal card_moved(from_slot, to_slot)
signal card_drag_started(card)
signal card_drag_ended(card, from_slot, to_slot)

func _ready():
	$Visuals/FrontFace.visible = false
	$Visuals/BackFace.visible = true
	$Visuals/Label.visible = false
	input_event.connect(_on_input_event)
	
func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() + drag_offset
		
		# 检测鼠标悬停的卡槽
		_check_hovered_slot()

func flip():
	is_face_up = true
	$Visuals/FrontFace.visible = true
	$Visuals/BackFace.visible = false
	$Visuals/Label.visible = true
	update_label()
	
	# 记录翻牌时间
	flip_time = Time.get_ticks_msec()
	
	# 根据卡牌类型设置正面图片
	match card_type:
		CardType.FRIEND:
			$Visuals/FrontFace.texture = load("res://assets/card/friend.png")
		CardType.ENEMY:
			$Visuals/FrontFace.texture = load("res://assets/card/enemy.png")
		CardType.EQUIPMENT:
			if attack > 0:
				$Visuals/FrontFace.texture = load("res://assets/card/sword.png")
			else:
				$Visuals/FrontFace.texture = load("res://assets/card/shield.png")
	
	# 确保翻牌后卡牌回到正确位置
	if current_slot != null:
		global_position = current_slot.global_position

func init_card(type: int, hp: int, atk: int, ap: int):
	card_type = type
	health = hp
	attack = atk
	action_points = ap
	max_action_points = ap
	
func update_label():
	$Visuals/Label.text = "AP: %d/%d\n\n\n\n ATK: %d   HP: %d" % [action_points, max_action_points, attack, health]


func reset_action_points():
	action_points = max_action_points
	update_label()

func consume_action_point():
	if action_points > 0:
		action_points -= 1
		update_label()
		return true
	return false

func equip_item(equipment):
	if equipment == null:
		return
	# 创建短暂变绿效果
	var tween = create_tween()
	# 立即变绿
	modulate = Color(0, 1, 0, 1) 
	# 0.2秒内恢复正常颜色
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	equipped_items.append(equipment)
	health += equipment.health
	attack += equipment.attack
	max_action_points += equipment.action_points
	action_points += equipment.action_points
	update_label()

func take_damage(damage_amount):
	health -= damage_amount
	update_label()
	
	# 创建短暂变红效果
	var tween = create_tween()
	# 立即变红
	modulate = Color(1, 0, 0, 1) 
	# 0.2秒内恢复正常颜色
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	
	if health <= 0:
		await tween.finished
		# 在销毁前断开所有信号连接
		disconnect_all_signals()
		queue_free()
		return true
	return false

# 断开所有信号连接
func disconnect_all_signals():
	var connections = get_signal_connection_list("card_clicked")
	for connection in connections:
		card_clicked.disconnect(connection.callable)
		
	connections = get_signal_connection_list("card_moved")
	for connection in connections:
		card_moved.disconnect(connection.callable)
		
	connections = get_signal_connection_list("card_drag_started")
	for connection in connections:
		card_drag_started.disconnect(connection.callable)
		
	connections = get_signal_connection_list("card_drag_ended")
	for connection in connections:
		card_drag_ended.disconnect(connection.callable)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 开始拖动
				if can_be_dragged():
					# 检查是否刚刚翻牌（500毫秒内不允许拖动）
					if Time.get_ticks_msec() - flip_time < 500:
						return
						
					dragging = true
					drag_offset = position - get_global_mouse_position()
					original_position = position
					original_z_index = z_index
					z_index = 100  # 将卡牌置于顶层
					card_drag_started.emit(self)
					get_viewport().set_input_as_handled()
			else:
				# 结束拖动
				if dragging:
					dragging = false
					z_index = original_z_index  # 恢复原来的z_index
					
					# 如果鼠标释放在某个卡槽上，则尝试与之交互
					if hovered_slot != null and current_slot != null:
						# 只发出信号，具体交互逻辑由GameManager处理
						card_drag_ended.emit(self, current_slot, hovered_slot)
					else:
						# 如果没有在卡槽上释放，则返回原位
						global_position = current_slot.global_position if current_slot else original_position
					
					hovered_slot = null
					get_viewport().set_input_as_handled()
			
			# 非拖动模式下的点击仍然触发卡牌点击信号
			if not dragging:
				# 检查是否刚刚翻牌（500毫秒内不响应点击）
				if Time.get_ticks_msec() - flip_time < 500:
					return
					
				card_clicked.emit(self)

func can_be_dragged() -> bool:
	# 只有友方角色牌且正面朝上时可拖动
	if not is_face_up:
		return false
		
	if card_type != CardType.FRIEND:
		return false
		
	# 验证卡牌是否有行动点
	if action_points <= 0:
		return false
		
	# 防止刚翻开的卡牌立即拖动
	if Time.get_ticks_msec() - flip_time < 500: # 500毫秒内不允许拖动
		return false
		
	return true

func set_current_slot(slot):
	current_slot = slot
	if slot != null:
		# 确保卡牌位于卡槽中心
		global_position = slot.global_position

func _check_hovered_slot():
	# 使用简单的距离检测来查找当前鼠标位置下的卡槽
	var mouse_pos = get_global_mouse_position()
	
	# 临时变量存储检测到的卡槽
	var found_slot = null
	var min_distance = 100.0  # 设置一个合理的阈值
	
	# 遍历场景中的所有卡槽节点
	var slots = get_tree().get_nodes_in_group("card_slot")
	for slot in slots:
		# 计算鼠标位置与卡槽中心的距离
		var distance = mouse_pos.distance_to(slot.global_position)
		# 如果距离在阈值内且比之前找到的更近
		if distance < min_distance:
			min_distance = distance
			found_slot = slot
	
	# 更新悬停的卡槽
	hovered_slot = found_slot
