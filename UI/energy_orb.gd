extends Area2D

@export var energy_value: int = 5
@export var lifetime: float = 10.0
@export var float_speed: float = 30.0
@export var float_duration: float = 1.5
@export var fade_after_float: bool = true

var _spawn_position: Vector2
var _target_position: Vector2
var _elapsed: float = 0.0
var _collected: bool = false

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	print("[Orb] _ready() BẮT ĐẦU")
	
	z_index = 100
	input_pickable = true
	
	print("[Orb] Pickable=", input_pickable, " Z=", z_index)
	
	_spawn_position = global_position
	_target_position = _spawn_position + Vector2(randf_range(-30, 30), -60)
	
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	print("[Orb] Signals connected OK")
	
	if sprite:
		sprite.scale = Vector2(0.3, 0.3)
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)
	
	print("[Orb] _ready() HOÀN TẤT")
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


func _on_mouse_entered() -> void:
	print("[Orb] Chuột VÀO orb")


func _on_mouse_exited() -> void:
	print("[Orb] Chuột RA khỏi orb")


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	print("[Orb] input_event nhận được: ", event)
	if _collected:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("[Orb] CLICKED!")
			_collect()


func _collect() -> void:
	if _collected:
		return
	_collected = true
	
	GameState.add_energy(energy_value)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
	
	print("[Orb] Collected +", energy_value)


func _on_lifetime_timeout() -> void:
	if _collected:
		return
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
