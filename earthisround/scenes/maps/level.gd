class_name Level
extends Node2D

@export var left_level_cross_edge: String
@export var right_level_cross_edge: String
enum LEVELTYPE { NORMAL, LEFTMOST, RIGHTMOST }

@export var level_type: LEVELTYPE

signal world_edge_entered(change_level: String)
@onready var area_2d: Area2D = $Area2D

func _ready():
	area_2d.body_entered.connect(_on_world_dege_area_entered)

func _on_world_dege_area_entered(_body: Node2D):
	match level_type:
		LEVELTYPE.NORMAL:
			return
		LEVELTYPE.LEFTMOST:
			world_edge_entered.emit(left_level_cross_edge)
		LEVELTYPE.RIGHTMOST:
			world_edge_entered.emit(right_level_cross_edge)
		_:
			return
