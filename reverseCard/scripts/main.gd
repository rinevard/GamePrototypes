extends Node2D

# 游戏主节点，负责初始化和场景管理

func _ready():
	# 确保GameManager正确初始化
	$GameManager.card_board = $GameBoard
	
	# 连接GameBoard和GameManager中的信号
	$GameManager.connect_signals()
	
	print("卡牌游戏初始化完成")

func _process(_delta):
	# 检测重新开始游戏的输入
	if Input.is_action_just_pressed("ui_cancel"):
		_restart_game()

func _restart_game():
	# 重新加载当前场景
	get_tree().reload_current_scene() 
