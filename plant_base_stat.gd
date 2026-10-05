class_name Plant
extends Node2D

@export var max_health: int = 50
var current_health: int
var _is_dead: bool = false

# Dùng get_node_or_null để không crash nếu thiếu node
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var hit_area: Area2D = get_node_or_null("HitArea")


func _ready() -> void:
	current_health = max_health
	
	# ⚠️ QUAN TRỌNG: add_to_group ở ĐẦU, trước mọi thứ có thể crash
	if not is_in_group("plants"):
		add_to_group("plants")
	print("[", name, "] Plant base ready. groups=", get_groups())
	
	# Kết nối HitArea nếu có (dùng null check, không crash)
	if hit_area:
		hit_area.body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node) -> void:
	# Override ở class con nếu cần
	pass


func take_damage(amount: int) -> void:
	if _is_dead:
		return
	
	current_health -= amount
	print("[", name, "] Nhận ", amount, " dmg. HP còn: ", current_health)
	
	if current_health <= 0:
		_die()
	else:
		_flash()


func _flash() -> void:
	if not sprite:
		return
	var tween = create_tween()
	sprite.modulate = Color(2, 0.5, 0.5, 1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _die() -> void:
	_is_dead = true
	remove_from_group("plants")
	print("[", name, "] Cây đã chết")
	
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()
