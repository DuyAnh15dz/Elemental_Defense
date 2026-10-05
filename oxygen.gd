extends Plant

signal shot_fired

@export var bullet_scene: PackedScene
@export var fire_interval: float = 1.5
@export var fire_direction: Vector2 = Vector2.RIGHT
@export var bullet_damage: int = 10
@export var bullet_speed: float = 400.0
@export var muzzle_offset: Vector2 = Vector2(60, -10)
@export var detect_range: float = 800.0

var _fire_timer: float = 0.0

@onready var detector: RayCast2D = get_node_or_null("EnemyDetector")


func _ready() -> void:
	# Gọi _ready() của Plant base
	if super.has_method("_ready"):
		super._ready()
	
	# Override chỉ số riêng cho cây Oxy
	max_health = 50
	current_health = max_health
	_fire_timer = fire_interval
	
	# Cảnh báo nếu chưa gán bullet_scene
	if bullet_scene == null:
		push_warning("Oxy: bullet_scene chưa được gán trong Inspector!")
	
	# Setup RayCast
	if detector:
		detector.enabled = true
		detector.target_position = Vector2(detect_range, 0)
		detector.collision_mask = 2
		detector.collide_with_areas = false
		detector.collide_with_bodies = true
		print("[", name, "] RayCast setup OK. target=", detector.target_position, " mask=", detector.collision_mask)
	else:
		push_warning("Oxy: Không tìm thấy node EnemyDetector!")


func _process(delta: float) -> void:
	if _is_dead:
		return
	if bullet_scene == null:
		return
	
	# Chỉ đếm giờ khi có enemy trong tầm
	if not _has_enemy_in_range():
		return
	
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		_fire_bullet()


# ─── PHÁT HIỆN ENEMY THEO ĐƯỜNG THẲNG ───
func _has_enemy_in_range() -> bool:
	if not detector:
		return false
	
	detector.force_raycast_update()
	
	if not detector.is_colliding():
		return false
	
	var collider = detector.get_collider()
	if collider == null:
		return false
	
	return collider.is_in_group("enemies")


func _fire_bullet() -> void:
	if bullet_scene == null:
		return
	
	var spawn_pos = global_position + muzzle_offset
	var bullet = bullet_scene.instantiate()
	bullet.global_position = spawn_pos
	
	if "direction" in bullet:
		bullet.direction = fire_direction
	if "damage" in bullet:
		bullet.damage = bullet_damage
	if "speed" in bullet:
		bullet.speed = bullet_speed
	
	get_tree().current_scene.add_child(bullet)
	shot_fired.emit()
