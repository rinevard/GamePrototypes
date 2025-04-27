extends CharacterBody2D

const SPEED = 140.0
const JUMP_VELOCITY = -200.0


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	MetSys.set_player_position(global_position)


var half_len: float = 12
func _get_clear_range() -> Array[Vector2]:
	var res: Array[Vector2] = []
	for x in range(-half_len, half_len):
		for y in range(-half_len, half_len):
			res.append(global_position + Vector2(x, y))
	return res

signal need_clear_range(range_to_clear: Array[Vector2])
func _input(event):
	if event.is_action_released("enter"):
		need_clear_range.emit(_get_clear_range())
