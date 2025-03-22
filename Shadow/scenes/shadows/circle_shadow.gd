class_name CircleShadow
extends CharacterBody2D

## 每秒一圈
var angular_velocity: float = PI
var radius: float = 600.0

func _ready():
	position.y = radius

## 绕原点顺时针转动
func rotate_around(delta: float):
	var angle = angular_velocity * delta
	var rotation_matrix = Transform2D(angle, Vector2.ZERO)
	position = rotation_matrix * position

## 处理每帧
func _physics_process(delta: float):
	rotate_around(delta)
	move_and_slide()
