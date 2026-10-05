extends Area2D

@export var energy_value: int = 5
@export var lifetime: float = 10.0          # Orb tự hủy sau 10s nếu không click
@export var float_speed: float = 30.0       # Tốc độ bay lên
@export var float_duration: float = 1.5     # Thời gian bay lên
@export var fade_after_float: bool = true   # Sau khi bay lên thì mờ dần

var _spawn_position: Vector2
var _target_position: Vector2
var _elapsed: float = 0.0
var _collected: bool = false

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	_spawn_position = global_position
	# Bay lên trên 60px rồi dừng
	_target_position = _spawn_position + Vector2(
		randf_range(-30, 30),   # lệch ngang ngẫu nhiên
		-60                      # bay lên 60px
	)
	
	# Kết nối input
	input_event.connect(_on_input_event)
	
	# Hiệu ứng pop khi spawn
	if sprite:
		sprite.scale = Vector2(0.3, 0.3)
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Tự hủy sau lifetime
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)


func _process(delta: float) -> void:
	if _collected:
		return
	
	_elapsed += delta
	
	# Giai đoạn 1: bay lên
	if _elapsed < float_duration:
		var t = _elapsed / float_duration
		global_position = _spawn_position.lerp(_target_position, t)
	else:
		# Giai đoạn 2: đứng yên, nhấp nhô nhẹ
		var bob = sin(Time.get_ticks_msec() * 0.005) * 3.0
		global_position = _target_position + Vector2(0, bob)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _collected:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_collect()


func _collect() -> void:
	if _collected:
		return
	_collected = true
	
	# Cộng năng lượng
	GameState.add_energy(energy_value)
	
	# Hiệu ứng biến mất
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
	
	print("[Orb] Collected +", energy_value)


func _on_lifetime_timeout() -> void:
	if _collected:
		return
	
	# Mờ dần rồi biến mất
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
