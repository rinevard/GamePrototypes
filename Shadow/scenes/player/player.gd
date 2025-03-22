extends CharacterBody2D

@onready var player_action_component: PlayerActionComponent = $PlayerActionComponent

# 墨
const INK_SHADOW = preload("res://scenes/shadows/ink_shadow.tscn")
var ink_shadow: Node2D = null

var ink_pressed_time: int = 0:
	set(value):
		ink_pressed_time = value
		if ink_pressed_time == 0:
			if ink_shadow and is_instance_valid(ink_shadow):
				ink_shadow.call_deferred("queue_free")
		elif ink_pressed_time == 1:
			ink_shadow = INK_SHADOW.instantiate()
			get_tree().root.add_child(ink_shadow)
			ink_shadow.global_position = global_position
		else:
			# 互换位置
			var tmp = global_position
			global_position = ink_shadow.global_position
			ink_shadow.global_position = tmp

# 循迹相关
const PATH_SHADOW = preload("res://scenes/shadows/path_shadow.tscn")
var is_recording_path: bool = false
var path_shadow_born_global_pos: Vector2
var path_shadow: PathShadow = null
var last_global_pos: Vector2

var path_pressed_time: int = 0:
	set(value):
		path_pressed_time = value
		if path_pressed_time == 0:
			PathRecorder.reset_shift_record()
			PathRecorder.end_record_shift()
			is_recording_path = false
			if path_shadow and is_instance_valid(path_shadow):
				path_shadow.call_deferred("queue_free")
		elif path_pressed_time == 1:
			PathRecorder.start_record_shift()
			is_recording_path = true
			path_shadow_born_global_pos = global_position
			print("开始记录!")
		elif path_pressed_time == 2:
			path_shadow = PATH_SHADOW.instantiate()
			get_tree().root.add_child(path_shadow)
			path_shadow.global_position = path_shadow_born_global_pos
			path_shadow.all_shift_completed.connect(_on_all_shifts_completed)
			_on_all_shifts_completed()
		else:
			# 互换位置
			var tmp = global_position
			global_position = path_shadow.global_position
			path_shadow.global_position = tmp

# 仿行相关
const IMITATION_SHADOW = preload("res://scenes/shadows/imitation_shadow.tscn")
var is_recording_action: bool = false
var imitation_shadow_born_global_pos: Vector2
var imitation_shadow: ImitationShadow = null

var imitation_pressed_time: int = 0:
	set(value):
		imitation_pressed_time = value
		if imitation_pressed_time == 0:
			ActionRecorder.reset_action_record()
			ActionRecorder.end_record_action()
			is_recording_action = false
			if imitation_shadow and is_instance_valid(imitation_shadow):
				imitation_shadow.call_deferred("queue_free")
		elif imitation_pressed_time == 1:
			ActionRecorder.start_record_action()
			is_recording_action = true
			imitation_shadow_born_global_pos = global_position
			print("开始记录!")
		elif imitation_pressed_time == 2:
			imitation_shadow = IMITATION_SHADOW.instantiate()
			get_tree().root.add_child(imitation_shadow)
			imitation_shadow.global_position = imitation_shadow_born_global_pos
			imitation_shadow.all_action_completed.connect(_on_all_actions_completed)
			_on_all_actions_completed()
		else:
			# 互换位置
			var tmp = global_position
			global_position = imitation_shadow.global_position
			imitation_shadow.global_position = tmp

# 小镜子
const MIRROR_SHADOW = preload("res://scenes/shadows/mirror_shadow.tscn")
var mirror_shadow_born_global_pos_x: float 
var mirror_shadow: Node2D
var mirror_pressed_time: int = 0:
	set(value):
		mirror_pressed_time = value
		if mirror_pressed_time == 0: # 移除它以后
			if mirror_shadow and is_instance_valid(mirror_shadow):
				mirror_shadow.call_deferred("queue_free")
		elif mirror_pressed_time == 1: # 召唤时
			mirror_shadow = MIRROR_SHADOW.instantiate()
			mirror_shadow.global_position = global_position
			mirror_shadow_born_global_pos_x = global_position.x
			get_tree().root.add_child(mirror_shadow)
		else:
			# 互换位置
			var tmp = global_position
			global_position = mirror_shadow.global_position
			mirror_shadow.global_position = tmp

# 环
const CIRCLE_SHADOW = preload("res://scenes/shadows/circle_shadow.tscn")
var circle_shadow: Node2D
var circle_pressed_time: int = 0:
	set(value):
		circle_pressed_time = value
		var tmp = global_position
		global_position = circle_shadow.global_position
		circle_shadow.global_position = tmp

func _ready():
	circle_shadow =  CIRCLE_SHADOW.instantiate()
	add_child(circle_shadow)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var actions: Array[int] = []
	if Input.is_action_pressed("jump"):
		actions.append(Enum.Actions.JUMP)
	if Input.is_action_pressed("left"):
		actions.append(Enum.Actions.LEFT)
	if Input.is_action_pressed("right"):
		actions.append(Enum.Actions.RIGHT)
	
	player_action_component.handle_action(actions)
	
	# 仿行
	if is_recording_action:
		ActionRecorder.call_deferred("record_action", actions)
	
	# 循迹
	if is_recording_path:
		PathRecorder.call_deferred("record_shift", global_position - last_global_pos)
	last_global_pos = global_position
	
	# 镜
	if mirror_shadow and is_instance_valid(mirror_shadow):
		mirror_shadow.global_position.x = 2 * mirror_shadow_born_global_pos_x - global_position.x
		mirror_shadow.global_position.y = global_position.y
	
	move_and_slide()

func _unhandled_input(event):
	# 仿行
	if event.is_action_pressed("remove-imitation"):
		imitation_pressed_time = 0
	elif event.is_action_pressed("simulate-imitation"):
		imitation_pressed_time += 1
	
	# 墨
	if event.is_action_pressed("remove-ink"):
		ink_pressed_time = 0
	elif event.is_action_pressed("ink"):
		ink_pressed_time += 1
	
	# 循迹
	if event.is_action_pressed("remove-path"):
		path_pressed_time = 0
	elif event.is_action_pressed("simulate-path"):
		path_pressed_time += 1
	
	# 镜
	if event.is_action_pressed("remove-mirror"):
		mirror_pressed_time = 0
	elif event.is_action_pressed("mirror"):
		mirror_pressed_time += 1
	
	# 环
	if event.is_action_pressed("circle"):
		circle_pressed_time += 1

func _on_all_actions_completed():
	assert(is_instance_valid(imitation_shadow) and imitation_shadow != null, "在 imitation_shadow 不合法时调用了 _on_actions_completed!")
	var actions = ActionRecorder.get_record_actions()
	imitation_shadow.repeat_actions(actions)
	ActionRecorder.reset_action_record()

func _on_all_shifts_completed():
	assert(is_instance_valid(path_shadow) and path_shadow != null, "在 path_shadow 不合法时调用了 _on_all_shifts_completed!")
	var shifts = PathRecorder.get_record_shifts()
	path_shadow.repeat_shifts(shifts)
	PathRecorder.reset_shift_record()
