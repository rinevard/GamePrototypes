extends Node

"""
关于仿行
大致思路可以是这样的:
	按下按钮时调用 reset_action_record() 和 start_record_action() 来重置并开始记录
	持续调用 record_action() 来记录
	再次按下仿行时开始复读:
		首先调用 end_record_action() 来终止记录, 用 get_record_actions 获取记录,
		然后 for act, time in 记录:
			 # 这一行是为了复读
			 act_after_time(act, time): await time; do action
			 # 下面是为了保证仿行实体化后仍然在记录
			 max_time = max(max_time, time)
			(func(time): all_past_actions_completed.emit())(max_time)
		之后重置并重新开始记录, 直到收到 all_past_actions_completed 的信号又开始重复复读.
		数据变化大概是这样的:
			第一次按下仿行: []
			第二次按下仿行瞬间前: [[act1, time1], [act2, time2], ...]
			第二次按下仿行瞬间后: []
				这时所有的操作都进入了仿行的 TODO
			在 TODO 做完的瞬间前: [[act1, time1], [act2, time2], ...]
				我们在仿行做 TODO 的过程中又新增了很多记录
			在 TODO 做完的瞬间后: []
				新增的记录重新进入 TODO, 我们也重新开始记录
"""
## 输入的 actions 是形如[[[actions], time1], [[actions], time2], ...] 的列表, time 的单位为秒
## time1 从 0 开始, time_k 对应的 actions 表示在 time_k 时按下的所有动作. 如果那一刻没有按下动作, actions 为空列表
var action_time_queue: Array[Array] = []
var is_recording_action: bool = false
var action_record_start_sec: float = -1.0 # 单位为秒

## 清空记录的操作
func reset_action_record():
	action_record_start_sec = Time.get_ticks_msec() / 1000.0
	action_time_queue = []

## 开始记录操作
func start_record_action():
	is_recording_action = true
	action_record_start_sec = Time.get_ticks_msec() / 1000.0

## 结束记录操作
func end_record_action():
	is_recording_action = false
	action_record_start_sec = -1.0

## 调用该函数来记录玩家的操作
## 在记录前应当先调用 start_record_action 来开始记录
func record_action(actions: Array[int]):
	assert(is_recording_action, "尚未开始记录 action!")
	for action in actions:
		assert(action in Enum.Actions.values(), "要记录的 action 不在 Enum.Actions 里! action 为 " + str(action))
	var cur_sec: float = Time.get_ticks_msec() / 1000.0
	action_time_queue.append([actions, cur_sec - action_record_start_sec])

## 返回截至调用该函数时记录的所有操作
var time: int = 0
func get_record_actions() -> Array:
	time += 1
	return action_time_queue.duplicate(true)
