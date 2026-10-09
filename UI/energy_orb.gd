extends Area2D

@export var energy_value: int = 25
@export var lifetime: float = 10.0          # Orb tự hủy sau 10s nếu không click
@export var float_speed: float = 30.0       # Tốc độ bay lên
@export var float_duration: float = 1.5     # Thời gian bay lên
@export var fade_after_float: bool = true   # Sau khi bay lên thì mờ dần
@export var fly_time: float = 0.6           # Thời gian bay tới icon năng lượng

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
	
	# Tắt input để không click trùng lần nữa
	input_pickable = false
	
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null or not hud.has_method("get_energy_icon_screen_pos"):
		# Không tìm thấy HUD -> cộng năng lượng và mờ dần tại chỗ
		GameState.add_energy(energy_value)
		var t = create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.2)
		t.tween_callback(queue_free)
		return
	
	# Đổi toạ độ màn hình của icon (CanvasLayer) sang toạ độ thế giới
	var screen_pos: Vector2 = hud.get_energy_icon_screen_pos()
	var world_target: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	
	var tween = create_tween()
	# Bay thẳng tới icon năng lượng
	tween.tween_property(self, "global_position", world_target, fly_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Nhỏ dần trong lúc bay
	tween.parallel().tween_property(self, "scale", scale * 0.6, fly_time)
	# Mờ dần ở phần cuối hành trình
	tween.parallel().tween_property(self, "modulate:a", 0.0, fly_time * 0.4)\
		.set_delay(fly_time * 0.6)
	# Đến nơi mới cộng năng lượng (label HUD sẽ nảy lên đúng lúc)
	tween.tween_callback(func():
		GameState.add_energy(energy_value)
		queue_free()
	)
	
	print("[Orb] Collected +", energy_value)


func _on_lifetime_timeout() -> void:
	if _collected:
		return
	
	# Mờ dần rồi biến mất
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
