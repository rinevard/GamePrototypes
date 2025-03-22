extends Node

## 输入的 shifts 是形如[[shift, time1], [shift, time2], ...] 的列表, time 的单位为秒
## time1 从 0 开始, time_k 对应的 shift 表示在 time_k 时的位移. 如果那一刻没有按下动作, shifts 为空列表
var shift_time_queue: Array = []
var is_recording_shift: bool = false
var shift_record_start_sec: float = -1.0 # 单位为秒
var global_pos_last_record: Vector2

## 清空记录的操作
func reset_shift_record():
	shift_record_start_sec = Time.get_ticks_msec() / 1000.0
	shift_time_queue = []

## 开始记录操作
func start_record_shift():
	is_recording_shift = true
	shift_record_start_sec = Time.get_ticks_msec() / 1000.0

## 结束记录操作
func end_record_shift():
	is_recording_shift = false
	shift_record_start_sec = -1.0

## 调用该函数来记录玩家的操作
## 在记录前应当先调用 start_record_shift 来开始记录
func record_shift(shift: Vector2):
	assert(is_recording_shift, "尚未开始记录 shift!")
	var cur_sec: float = Time.get_ticks_msec() / 1000.0
	shift_time_queue.append([shift, cur_sec - shift_record_start_sec])

## 返回截至调用该函数时记录的所有操作
var time: int = 0
func get_record_shifts() -> Array:
	time += 1
	return shift_time_queue.duplicate(true)
