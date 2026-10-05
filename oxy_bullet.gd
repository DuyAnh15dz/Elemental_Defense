extends Area2D

# ===== Cấu hình (ĐẶT LÊN ĐẦU) =====
@export var speed: float = 400.0
@export var direction: Vector2 = Vector2.RIGHT
@export var damage: int = 10
@export var life_time: float = 5.0
@export var frame_duration: float = 0.08
@export var bullet_scale: float = 0.08

# ===== Frames =====
@export var bounce_frames: Array[Texture2D] = []
@export var pop_frame: Texture2D

# ===== Nội bộ =====
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _frame_index: int = 0
var _frame_dir: int = 1
var _frame_timer: float = 0.0
var _has_popped: bool = false


func _ready() -> void:
	# Chỉ scale Sprite2D, KHÔNG scale CollisionShape2D
	sprite.scale = Vector2(bullet_scale, bullet_scale)
	
	# Gán frame đầu tiên
	if bounce_frames.size() > 0:
		sprite.texture = bounce_frames[0]
	
	# Tự hủy sau life_time
	get_tree().create_timer(life_time).timeout.connect(_on_life_timeout)
	
	# Kết nối signal va chạm
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _has_popped:
		return
	
	# Di chuyển thẳng
	position += direction.normalized() * speed * delta
	
	# Đổi frame theo chu kỳ 0 → 1 → 2 → 1 → 0
	_frame_timer += delta
	if _frame_timer >= frame_duration:
		_frame_timer = 0.0
		_frame_index += _frame_dir
		
		if _frame_index >= bounce_frames.size() - 1 or _frame_index <= 0:
			_frame_dir *= -1
			_frame_index = clampi(_frame_index, 0, bounce_frames.size() - 1)
		
		sprite.texture = bounce_frames[_frame_index]


func _on_area_entered(area: Area2D) -> void:
	print("Bullet chạm Area: ", area.name, " | group enemies? ", area.is_in_group("enemies"))
	if _has_popped: return
	if area.is_in_group("enemies"):
		_damage_and_pop(area)

func _on_body_entered(body: Node2D) -> void:
	print("Bullet chạm Body: ", body.name, " | group enemies? ", body.is_in_group("enemies"))
	if _has_popped: return
	if body.is_in_group("enemies"):
		_damage_and_pop(body)

func _damage_and_pop(target: Node) -> void:
	if _has_popped:
		return
	_has_popped = true
	
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	if pop_frame != null:
		sprite.texture = pop_frame
	
	speed = 0.0
	get_tree().create_timer(0.2).timeout.connect(queue_free)


func _on_life_timeout() -> void:
	if not _has_popped:
		queue_free()
