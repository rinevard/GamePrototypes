class_name PathShadow
extends CharacterBody2D

signal all_shift_completed()

## 记录尚未完成的位移数量, 在所有动作列表完成后发出信号来获取新的 actions
var shift_num_to_complete: int = 0:
	set(num):
		shift_num_to_complete = num
		if shift_num_to_complete == 0:
			all_shift_completed.emit()
var cur_pressed_shifts: Array[Vector2] = []

## 输入的 shifts 是形如[[shift, time1], [shift, time2], ...] 的列表, time 的单位为秒
## time1 从 0 开始, time_k 对应的 shift 表示在 time_k 时的位移. 如果那一刻没有按下动作, shifts 为空列表
func repeat_shifts(shifts: Array):
	for tuple in shifts:
		var shift: Vector2 = tuple[0]
		var time = tuple[1]
		shift_after_time(shift, time)

## 在 time 时间后移动自身
func shift_after_time(shift: Vector2, time: float):
	shift_num_to_complete += 1
	await get_tree().create_timer(time).timeout
	global_position += shift
	shift_num_to_complete -= 1 
