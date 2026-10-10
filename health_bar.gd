# Thanh máu dùng chung cho cây và quái. Add làm con của node có máu.
class_name HealthBar
extends Node2D

@export var bar_size := Vector2(40, 5)
@export var offset := Vector2(0, -40)        # lệch so với tâm node cha
@export var hide_when_full := true           # chỉ hiện khi đã mất máu
@export var health_prop := "current_health"  # tên biến máu hiện tại của node cha
@export var max_prop := "max_health"         # tên biến máu tối đa của node cha

var _target: Node
var _ratio := -1.0

func _ready() -> void:
	_target = get_parent()
	top_level = true   # không thừa hưởng scale/flip/modulate (tint, flash) của node cha
	z_index = 20

func _process(_delta: float) -> void:
	if not is_instance_valid(_target):
		return
	global_position = _target.global_position + offset
	var cur := float(_target.get(health_prop))
	var mx := maxf(float(_target.get(max_prop)), 1.0)
	var r := clampf(cur / mx, 0.0, 1.0)
	if not is_equal_approx(r, _ratio):
		_ratio = r
		queue_redraw()
	visible = cur > 0.0 and not (hide_when_full and r >= 1.0)

func _draw() -> void:
	var rect := Rect2(-bar_size.x / 2.0, 0.0, bar_size.x, bar_size.y)
	draw_rect(rect, Color(0, 0, 0, 0.6))  # nền
	var col := Color(0.3, 0.9, 0.3)
	if _ratio <= 0.25:
		col = Color(0.9, 0.2, 0.2)
	elif _ratio <= 0.5:
		col = Color(0.95, 0.8, 0.2)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * _ratio, rect.size.y)), col)
	draw_rect(rect, Color.BLACK, false, 1.0)  # viền
