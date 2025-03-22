class_name PlayerActionComponent
extends Node2D

@export var character_body: CharacterBody2D
@export var speed: float = 900.0
@export var jump_velocity: float = -1550.0

## 接受一个动作列表(autoload 里的 enum 值), 让 character_body 做出相应行为
## 如果输入为空列表, 表示没有输入的动作, character_body 将减速
func handle_action(actions: Array[int]):
	var flag = false
	if actions != [] and actions != [1] and actions != [0] and character_body.get("imitation_pressed_time") == null:
		print(actions)
		flag = true

	for action in actions:
		match action:
			Enum.Actions.LEFT:
				character_body.velocity.x = -1 * speed
			Enum.Actions.RIGHT:
				character_body.velocity.x = 1 * speed
			Enum.Actions.JUMP:
				if flag:
					print("is jumping!")
				if character_body.is_on_floor():
					if flag:
						print("真的跳起来了")
					character_body.velocity.y = jump_velocity
	if actions.size() == 0:
		character_body.velocity.x = move_toward(character_body.velocity.x, 0, speed)
