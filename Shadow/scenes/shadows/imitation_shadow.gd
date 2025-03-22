class_name ImitationShadow
extends CharacterBody2D

signal all_action_completed()
@onready var player_action_component: PlayerActionComponent = $PlayerActionComponent

## 记录尚未完成的 actions 列表数量, 在所有动作列表完成后发出信号来获取新的 actions
var action_num_to_complete: int = 0:
	set(num):
		action_num_to_complete = num
		if action_num_to_complete == 0:
			all_action_completed.emit()
var cur_pressed_actions: Array[int] = []

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	player_action_component.handle_action(cur_pressed_actions)

	move_and_slide()

## 输入的 actions 是形如[[[actions], time1], [[actions], time2], ...] 的列表, time 的单位为秒
## time1 从 0 开始, time_k 对应的 actions 表示在 time_k 时按下的所有动作. 如果那一刻没有按下动作, actions 为空列表
func repeat_actions(actions: Array[Array]):
	for tuple in actions:
		var actions_at_time = tuple[0]
		var time = tuple[1]
		act_after_time(actions_at_time, time)

## 在 time 时间后把 action 设为 cur_pressed_action
func act_after_time(actions_at_time: Array[int], time: float):
	action_num_to_complete += 1
	await get_tree().create_timer(time).timeout
	cur_pressed_actions = actions_at_time
	action_num_to_complete -= 1 
