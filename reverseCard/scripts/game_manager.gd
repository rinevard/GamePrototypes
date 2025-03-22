extends Node

enum GameState {SETUP, PLAYER_TURN, ENEMY_TURN, GAME_OVER}

var current_state = GameState.SETUP
var current_selected_card = null
var current_selected_slot = null
var flipped_cards_count = 0
var max_initial_flips = 2
var interaction_just_occurred = false # 防止多次交互的标志
var just_flipped_card = null # 记录刚刚翻开的卡牌

@onready var card_board = $"../GameBoard"

func _ready():
	# 连接信号
	card_board.card_flipped.connect(_on_card_flipped)
	card_board.enemy_turn_completed.connect(_on_enemy_turn_completed)
	
	# 设置空格键作为回合结束的输入
	if !InputMap.has_action("end_turn"):
		InputMap.add_action("end_turn")
	var event = InputEventKey.new()
	event.keycode = KEY_SPACE
	InputMap.action_add_event("end_turn", event)
	
	# 开始设置阶段
	_enter_setup_phase()

func _enter_setup_phase():
	current_state = GameState.SETUP
	print("游戏设置阶段: 翻开两张牌开始游戏")

func _enter_player_turn():
	current_state = GameState.PLAYER_TURN
	print("玩家回合")
	interaction_just_occurred = false
	just_flipped_card = null
	card_board.reset_action_points_for_friends()

func _enter_enemy_turn():
	current_state = GameState.ENEMY_TURN
	print("敌方回合")
	interaction_just_occurred = false
	just_flipped_card = null
	card_board.execute_enemy_turn()

func _enter_game_over(is_player_win):
	current_state = GameState.GAME_OVER
	if is_player_win:
		print("游戏结束: 玩家胜利!")
	else:
		print("游戏结束: 敌人胜利!")

func _process(_delta):
	match current_state:
		GameState.SETUP:
			if flipped_cards_count >= max_initial_flips:
				_enter_player_turn()
		
		GameState.PLAYER_TURN:
			# 检测空格键输入
			if Input.is_action_just_pressed("end_turn"):
				_enter_enemy_turn()
			
			# 每帧重置交互标志，防止多次交互
			if interaction_just_occurred:
				interaction_just_occurred = false
				
			# 重置刚刚翻开的卡牌
			if just_flipped_card != null:
				if Time.get_ticks_msec() - just_flipped_card.flip_time > 500: # 500毫秒后重置
					just_flipped_card = null
			
		GameState.ENEMY_TURN:
			# 敌方回合由card_board控制
			pass
			
		GameState.GAME_OVER:
			# 游戏结束，等待重启
			pass

func _on_card_flipped(card):
	if card == null:
		return
		
	if current_state == GameState.SETUP:
		flipped_cards_count += 1
	
	# 记录刚刚翻开的卡牌
	just_flipped_card = card
	card.flip_time = Time.get_ticks_msec() # 记录翻牌时间

func _on_enemy_turn_completed():
	_check_game_state()
	_enter_player_turn()

func _handle_slot_click(slot):
	if slot == null or interaction_just_occurred:
		return
		
	match current_state:
		GameState.SETUP:
			if slot.has_valid_card() and not slot.current_card.is_face_up:
				if flipped_cards_count < max_initial_flips:
					slot.current_card.flip()
					card_board.card_flipped.emit(slot.current_card)
				
		GameState.PLAYER_TURN:
			if current_selected_slot == null:
				if slot.has_valid_card() and slot.current_card.is_face_up and slot.current_card.card_type == 0:
					# 如果是刚刚翻开的卡牌，不要选中它
					if just_flipped_card == slot.current_card:
						return
						
					# 选择一个友方角色
					current_selected_slot = slot
					current_selected_card = slot.current_card
					print("已选择角色: HP:%d ATK:%d AP:%d/%d" % [
						current_selected_card.health, 
						current_selected_card.attack, 
						current_selected_card.action_points, 
						current_selected_card.max_action_points
					])
			else:
				# 检查是否可以交互
				if current_selected_slot.is_adjacent_to(slot):
					if current_selected_card != null and current_selected_card.action_points > 0:
						_handle_card_interaction(current_selected_slot, slot)
						interaction_just_occurred = true # 设置交互标志
						_check_game_state()
					else:
						print("行动点不足")
				else:
					print("目标位置不相邻")
					
				# 无论交互结果如何，取消选择
				current_selected_slot = null
				current_selected_card = null

func _handle_card_click(card):
	if card == null or not is_instance_valid(card) or interaction_just_occurred:
		return
		
	# 如果是刚刚翻开的卡牌，不响应点击
	if just_flipped_card == card:
		return
		
	if current_state == GameState.PLAYER_TURN:
		# 找到这张卡所在的槽位
		var card_slot = null
		for row in card_board.slots:
			for slot in row:
				if slot.current_card == card:
					card_slot = slot
					break
		
		if card_slot != null:
			_handle_slot_click(card_slot)

func _on_card_drag_started(card):
	if card == null or not is_instance_valid(card) or interaction_just_occurred:
		return
		
	# 如果是刚刚翻开的卡牌，不允许拖动
	if just_flipped_card == card:
		card.dragging = false # 取消拖动状态
		return
		
	# 记录开始拖拽的卡牌
	if current_state == GameState.PLAYER_TURN:
		# 清除之前的选择
		current_selected_slot = null
		current_selected_card = null
		
		# 从所在槽位中找到卡牌
		for row in card_board.slots:
			for slot in row:
				if slot.occupied and slot.current_card == card:
					current_selected_slot = slot
					current_selected_card = card
					print("开始拖动卡牌: HP:%d ATK:%d AP:%d/%d" % [
						card.health, card.attack, card.action_points, card.max_action_points
					])
					break

func _on_card_drag_ended(card, from_slot, to_slot):
	if card == null or not is_instance_valid(card) or from_slot == null or to_slot == null or interaction_just_occurred:
		if card != null and is_instance_valid(card) and card.current_slot != null:
			# 确保卡牌回到原位
			card.global_position = card.current_slot.global_position
		return
		
	if current_state == GameState.PLAYER_TURN:
		print("拖动结束: 从[%d,%d]到[%d,%d]" % [
			from_slot.grid_position.x, 
			from_slot.grid_position.y,
			to_slot.grid_position.x,
			to_slot.grid_position.y
		])
		
		# 验证交互是否有效
		if from_slot.is_adjacent_to(to_slot):
			if card.action_points > 0:
				# 根据目标槽位的情况执行适当的交互
				_handle_card_interaction(from_slot, to_slot)
				interaction_just_occurred = true # 设置交互标志
				_check_game_state()
			else:
				print("行动点不足")
				# 返回原位置
				card.global_position = from_slot.global_position
		else:
			print("目标位置不相邻")
			# 返回原位置
			card.global_position = from_slot.global_position
			
		# 交互完成后重置选择
		current_selected_slot = null
		current_selected_card = null

func _handle_card_interaction(from_slot, to_slot):
	if from_slot == null or to_slot == null or not from_slot.has_valid_card():
		return
		
	var actor_card = from_slot.current_card
	
	# 确保在交互前保存原始位置
	var original_position = actor_card.current_slot.global_position
	
	if not to_slot.occupied:
		# 移动到空位
		if card_board.move_card(from_slot, to_slot):
			actor_card.consume_action_point()
			print("卡牌移动到空位")
		return # 确保单次交互
	
	if not to_slot.has_valid_card():
		return
		
	var target_card = to_slot.current_card
	
	if not target_card.is_face_up:
		# 翻开卡牌
		target_card.flip()
		card_board.card_flipped.emit(target_card)
		actor_card.consume_action_point()
		
		# 确保卡牌回到原位
		print("原位: %s" % original_position)
		print("当前位置: %s" % actor_card.global_position)
		actor_card.global_position = original_position
		print("翻开卡牌: %d类型" % target_card.card_type)
		return # 确保单次交互
	
	# 根据交互类型处理
	match [actor_card.card_type, target_card.card_type]:
		[0, 0]: # 友方与友方交换位置
			var temp = from_slot.remove_card()
			var temp2 = to_slot.remove_card()
			to_slot.place_card(temp)
			from_slot.place_card(temp2)
			# 确保卡牌位置正确
			if temp != null: 
				temp.global_position = to_slot.global_position
			if temp2 != null:
				temp2.global_position = from_slot.global_position
				
			actor_card.consume_action_point()
			print("与友方角色交换位置")
			return # 确保单次交互
			
		[0, 1]: # 友方攻击敌方
			var was_destroyed = await target_card.take_damage(actor_card.attack)
			actor_card.consume_action_point()
			print("攻击敌方: 造成%d伤害" % actor_card.attack)
			
			# 如果敌方被消灭，释放槽位
			if was_destroyed:
				to_slot.remove_card()
			
			# 确保攻击后卡牌回到原位
			actor_card.global_position = original_position
			print("攻击敌方: 卡牌回到原位")
			return # 确保单次交互
			
		[0, 2]: # 友方获得装备
			# 记录装备位置
			var equipment_position = to_slot.global_position
			
			# 获得装备并移除装备卡牌
			actor_card.equip_item(target_card)
			actor_card.consume_action_point()
			
			# 移动友方角色到装备位置
			from_slot.remove_card()
			to_slot.remove_card() # 移除装备卡牌
			target_card.queue_free() # 销毁装备卡牌
			
			# 将友方角色移动到装备位置
			to_slot.place_card(actor_card)
			actor_card.global_position = equipment_position
			
			print("获得装备并移动到装备位置")
			return # 确保单次交互
			
		[1, 0]: # 敌方攻击友方
			var was_destroyed = target_card.take_damage(actor_card.attack)
			actor_card.consume_action_point()
			print("敌方攻击友方: 造成%d伤害" % actor_card.attack)
			
			# 如果友方被消灭，释放槽位
			if was_destroyed:
				to_slot.remove_card()
			
			# 确保攻击后卡牌回到原位
			actor_card.global_position = original_position
			return # 确保单次交互
			
		[1, 2]: # 敌方获得装备
			# 记录装备位置
			var equipment_position = to_slot.global_position
			
			# 获得装备并移除装备卡牌
			actor_card.equip_item(target_card)
			actor_card.consume_action_point()
			
			# 移动敌方角色到装备位置
			from_slot.remove_card()
			to_slot.remove_card() # 移除装备卡牌
			target_card.queue_free() # 销毁装备卡牌
			
			# 将敌方角色移动到装备位置
			to_slot.place_card(actor_card)
			actor_card.global_position = equipment_position
			
			print("敌方获得装备并移动到装备位置")
			return # 确保单次交互

func _check_game_state():
	var has_friend = false
	var has_enemy = false
	var all_cards_flipped = true
	
	# 检查场上是否还有友方和敌方角色，以及是否所有卡牌都已翻开
	for row in card_board.slots:
		for slot in row:
			if slot.has_valid_card():
				# 检查是否所有卡牌都已翻开
				if not slot.current_card.is_face_up:
					all_cards_flipped = false
				
				# 检查是否有友方和敌方角色
				if slot.current_card.is_face_up:
					if slot.current_card.card_type == 0: # 友方
						has_friend = true
					elif slot.current_card.card_type == 1: # 敌方
						has_enemy = true
	
	if not has_friend:
		_enter_game_over(false) # 玩家失败
	elif not has_enemy and all_cards_flipped:
		_enter_game_over(true) # 玩家胜利：没有敌人且所有卡牌都已翻开
	# 如果还有敌人或有卡牌未翻开，游戏继续

func connect_signals():
	# 连接所有卡槽和卡牌的信号
	for row in card_board.slots:
		for slot in row:
			if not slot.slot_clicked.is_connected(_handle_slot_click):
				slot.slot_clicked.connect(_handle_slot_click)
				
			if slot.has_valid_card():
				# 首先断开可能的重复连接
				if slot.current_card.card_clicked.is_connected(_handle_card_click):
					slot.current_card.card_clicked.disconnect(_handle_card_click)
				slot.current_card.card_clicked.connect(_handle_card_click)
				
				# 连接拖放相关的信号
				if slot.current_card.card_type == 0: # 友方角色
					if slot.current_card.card_drag_started.is_connected(_on_card_drag_started):
						slot.current_card.card_drag_started.disconnect(_on_card_drag_started)
					slot.current_card.card_drag_started.connect(_on_card_drag_started)
					
					if slot.current_card.card_drag_ended.is_connected(_on_card_drag_ended):
						slot.current_card.card_drag_ended.disconnect(_on_card_drag_ended)
					slot.current_card.card_drag_ended.connect(_on_card_drag_ended)
	
	print("所有信号已连接") 
