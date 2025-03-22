extends Node2D

const ROWS = 3
const COLS = 5
const SLOT_WIDTH = 100
const SLOT_HEIGHT = 150
const MARGIN = 20
const INITIAL_OFFSET = Vector2(100, 100)

var slots = []
# 场景路径变量，在实际项目中可通过Inspector面板设置
var slot_scene_path = "res://scenes/card/card_slot.tscn"
var card_scene_path = "res://scenes/card/card.tscn"

# 信号
signal card_flipped(card)
signal enemy_turn_completed

func _ready():
	_create_board()
	_setup_initial_cards()

func _create_board():
	for row in range(ROWS):
		var row_slots = []
		for col in range(COLS):
			var slot = load(slot_scene_path).instantiate()
			add_child(slot)
			slot.position = INITIAL_OFFSET + Vector2(col * (SLOT_WIDTH + MARGIN), row * (SLOT_HEIGHT + MARGIN))
			slot.set_grid_position(col, row)
			slot.slot_clicked.connect(_on_slot_clicked)
			row_slots.append(slot)
		slots.append(row_slots)

func _setup_initial_cards():
	# 创建并放置中心友方角色
	var center_row = ROWS / 2
	var center_col = COLS / 2
	var center_card = _create_card(0, 5, 2, 2) # 友方角色牌
	_place_card_at(center_card, center_row, center_col)
	center_card.flip()
	
	# 其余位置放置正面朝下的卡牌
	for row in range(ROWS):
		for col in range(COLS):
			if row == center_row and col == center_col:
				continue
			
			var card = _create_random_card()
			_place_card_at(card, row, col)

func _create_card(type: int, health: int, attack: int, action_points: int):
	var card = load(card_scene_path).instantiate()
	card.init_card(type, health, attack, action_points)
	card.card_clicked.connect(_on_card_clicked)
	return card

func get_weighted_random() -> int:
	var rand = randf()  # 生成0到1之间的随机数
	
	if rand < 0.1:  # 25%的概率
		return 0
	elif rand < 0.5:  # 40%的概率 (0.25 + 0.4)
		return 2
	else:  # 剩余35%的概率
		return 1

func _create_random_card():
	var type = get_weighted_random()  # 使用加权随机生成卡牌类型
	var health = 0
	var attack = 0
	var action_points = 0
	
	match type:
		0: # 友方角色
			health = randi_range(4, 5)
			attack = randi_range(1, 2)
			action_points = randi_range(1, 3)
		1: # 敌方角色
			health = randi_range(3, 7)
			attack = randi_range(1, 4)
			action_points = randi_range(1, 2)
		2: # 装备
			# 生成偏向攻击或防御的装备
			if randi() % 2 == 0: # 攻击装备
				attack = randi_range(1, 3)
				health = 0
			else: # 防御装备
				health = randi_range(1, 3)
				attack = 0
			var action_point_probability = randi_range(0, 4)
			if (action_point_probability >= 1): # 0.75概率为0，0.25概率为1
				action_points = 0
			else:
				action_points = 1
			
	return _create_card(type, health, attack, action_points)

func _place_card_at(card, row, col):
	if row < 0 or row >= ROWS or col < 0 or col >= COLS:
		return false
		
	var slot = slots[row][col]
	if slot.place_card(card):
		add_child(card)
		card.global_position = slot.global_position
		return true
	return false

func get_adjacent_slots(slot):
	if slot == null:
		return []
		
	var adjacents = []
	var pos = slot.grid_position
	
	# 检查上下左右四个方向
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for dir in directions:
		var new_pos = pos + dir
		if new_pos.x >= 0 and new_pos.x < COLS and new_pos.y >= 0 and new_pos.y < ROWS:
			adjacents.append(slots[new_pos.y][new_pos.x])
	
	return adjacents

func move_card(from_slot, to_slot):
	if from_slot == null or to_slot == null:
		return false
		
	if not from_slot.has_valid_card() or to_slot.occupied:
		return false
	
	if not from_slot.is_adjacent_to(to_slot):
		return false
		
	var card = from_slot.remove_card()
	if card == null:
		return false
		
	if to_slot.place_card(card):
		# 确保卡牌位于目标槽位的正确位置
		card.global_position = to_slot.global_position
		return true
	else:
		# 如果目标槽位无法放置卡牌，将卡牌放回原位
		from_slot.place_card(card)
		card.global_position = from_slot.global_position
		return false

func _on_slot_clicked(slot):
	# 由GameManager处理逻辑
	pass

func _on_card_clicked(card):
	# 由GameManager处理逻辑
	pass

func reset_action_points_for_friends():
	for row in slots:
		for slot in row:
			if slot.has_valid_card() and slot.current_card.card_type == 0: # 友方角色
				slot.current_card.reset_action_points()

func execute_enemy_turn():
	var enemy_cards = []
	
	# 收集所有敌方角色卡牌
	for row in slots:
		for slot in row:
			if slot.has_valid_card() and slot.current_card.is_face_up and slot.current_card.card_type == 1: # 敌方角色
				enemy_cards.append({"card": slot.current_card, "slot": slot})
	
	# 为每个敌方角色执行行动
	for enemy in enemy_cards:
		if enemy.card != null and is_instance_valid(enemy.card):
			_execute_enemy_action(enemy.card, enemy.slot)
	
	# 通知回合完成
	enemy_turn_completed.emit()

func _execute_enemy_action(enemy_card, enemy_slot):
	if enemy_card == null or not is_instance_valid(enemy_card) or enemy_slot == null:
		return
		
	enemy_card.reset_action_points()
	
	while enemy_card.action_points > 0:
		var target_slot = _find_target_for_enemy(enemy_slot)
		if target_slot == null:
			break
			
		if not enemy_slot.is_adjacent_to(target_slot):
			# 找出到目标的路径
			var path = _find_path_to_target(enemy_slot, target_slot)
			if path.size() > 1:
				var next_slot = path[1] # 路径中的下一个位置
				if next_slot.has_valid_card():
					if next_slot.current_card.is_face_up:
						# 与卡牌交互
						_interact_with_card(enemy_card, enemy_slot, next_slot)
						enemy_card.consume_action_point() # 消耗一个行动点
						# 等待一下，让玩家看清楚交互结果
						await get_tree().create_timer(0.5).timeout
						
						# 检查敌方卡牌是否还有效且位置是否已更新
						if enemy_card == null or not is_instance_valid(enemy_card):
							break
						# 更新敌方卡牌所在的槽位引用
						for row in slots:
							for slot in row:
								if slot.has_valid_card() and slot.current_card == enemy_card:
									enemy_slot = slot
									break
					else:
						# 翻开卡牌
						next_slot.current_card.flip()
						card_flipped.emit(next_slot.current_card)
						enemy_card.consume_action_point() # 消耗一个行动点
						# 确保敌方卡牌回到原位
						enemy_card.global_position = enemy_slot.global_position
						# 等待一下，让玩家看清楚翻牌结果
						await get_tree().create_timer(0.5).timeout
				else:
					# 移动到空位
					move_card(enemy_slot, next_slot)
					enemy_slot = next_slot
					enemy_card.consume_action_point() # 消耗一个行动点
					# 等待一下，让玩家看清楚移动
					await get_tree().create_timer(0.5).timeout
		else:
			# 直接与相邻卡牌交互
			_interact_with_card(enemy_card, enemy_slot, target_slot)
			enemy_card.consume_action_point() # 消耗一个行动点
			# 等待一下，让玩家看清楚交互结果
			await get_tree().create_timer(0.5).timeout
			
			# 检查敌方卡牌是否还有效且位置是否已更新
			if enemy_card == null or not is_instance_valid(enemy_card):
				break
			# 更新敌方卡牌所在的槽位引用
			for row in slots:
				for slot in row:
					if slot.has_valid_card() and slot.current_card == enemy_card:
						enemy_slot = slot
						break
		
		# 检查敌方卡牌是否还有效
		if enemy_card == null or not is_instance_valid(enemy_card) or enemy_card.health <= 0:
			break

func _find_target_for_enemy(enemy_slot):
	if enemy_slot == null:
		return null
		
	var closest_target = null
	var min_distance = 999
	
	# 寻找最近的友方角色或装备
	for row in slots:
		for slot in row:
			if slot.has_valid_card() and slot.current_card.is_face_up:
				if slot.current_card.card_type == 0 or slot.current_card.card_type == 2: # 友方角色或装备
					var distance = _calculate_distance(enemy_slot, slot)
					if distance < min_distance:
						min_distance = distance
						closest_target = slot
					elif distance == min_distance and randf() < 0.5:
						# 如果距离相同，有50%的几率选择这个新目标
						closest_target = slot
	
	return closest_target

func _calculate_distance(slot1, slot2):
	if slot1 == null or slot2 == null:
		return 999
		
	var pos1 = slot1.grid_position
	var pos2 = slot2.grid_position
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

func _find_path_to_target(start_slot, target_slot):
	if start_slot == null or target_slot == null:
		return []
		
	# 这里使用简单的直线路径（不考虑障碍）
	var path = [start_slot]
	var current = start_slot
	
	while current != target_slot:
		var current_pos = current.grid_position
		var target_pos = target_slot.grid_position
		
		# 决定是横向还是纵向移动
		if current_pos.x != target_pos.x and current_pos.y != target_pos.y:
			if randf() < 0.5:
				# 横向移动
				var dir = 1 if target_pos.x > current_pos.x else -1
				if current_pos.x + dir >= 0 and current_pos.x + dir < COLS:
					var next = slots[current_pos.y][current_pos.x + dir]
					path.append(next)
					current = next
				else:
					break
			else:
				# 纵向移动
				var dir = 1 if target_pos.y > current_pos.y else -1
				if current_pos.y + dir >= 0 and current_pos.y + dir < ROWS:
					var next = slots[current_pos.y + dir][current_pos.x]
					path.append(next)
					current = next
				else:
					break
		elif current_pos.x != target_pos.x:
			# 横向移动
			var dir = 1 if target_pos.x > current_pos.x else -1
			if current_pos.x + dir >= 0 and current_pos.x + dir < COLS:
				var next = slots[current_pos.y][current_pos.x + dir]
				path.append(next)
				current = next
			else:
				break
		else:
			# 纵向移动
			var dir = 1 if target_pos.y > current_pos.y else -1
			if current_pos.y + dir >= 0 and current_pos.y + dir < ROWS:
				var next = slots[current_pos.y + dir][current_pos.x]
				path.append(next)
				current = next
			else:
				break
				
		if path.size() > 10: # 避免无限循环
			break
	
	return path

func _interact_with_card(actor_card, actor_slot, target_slot):
	if actor_card == null or not is_instance_valid(actor_card) or actor_slot == null or target_slot == null:
		return
		
	# 保存交互前的原始位置以便复位
	var original_position = actor_card.global_position
		
	if not target_slot.occupied:
		# 移动到空位
		move_card(actor_slot, target_slot)
		return
		
	if not target_slot.has_valid_card():
		return
		
	var target_card = target_slot.current_card
	
	if not target_card.is_face_up:
		# 翻开卡牌
		target_card.flip()
		card_flipped.emit(target_card)
		# 确保卡牌回到原位
		actor_card.global_position = original_position
		return
		
	match [actor_card.card_type, target_card.card_type]:
		[0, 0], [1, 1]: # 友方与友方交换位置，或敌方与敌方交换位置
			# 交换位置
			var temp = actor_slot.remove_card()
			var temp2 = target_slot.remove_card()
			target_slot.place_card(temp)
			actor_slot.place_card(temp2)
			if temp != null:
				temp.global_position = target_slot.global_position
			if temp2 != null:
				temp2.global_position = actor_slot.global_position
			
		[0, 1], [1, 0]: # 角色攻击对方
			var was_destroyed = await target_card.take_damage(actor_card.attack)
			if was_destroyed:
				target_slot.remove_card() # 移除被消灭的卡牌
			
			# 确保攻击后卡牌回到原位
			actor_card.global_position = original_position
			
		[0, 2], [1, 2]: # 角色获得装备
			# 记录装备位置
			var equipment_position = target_slot.global_position
			
			# 获得装备并移除装备卡牌
			actor_card.equip_item(target_card)
			
			# 移动角色到装备位置
			actor_slot.remove_card()
			target_slot.remove_card() # 移除装备卡牌
			target_card.queue_free() # 销毁装备卡牌
			
			# 将角色移动到装备位置
			target_slot.place_card(actor_card)
			actor_card.global_position = equipment_position
